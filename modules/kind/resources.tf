
data "external" "subnet" {
  program = ["/bin/bash", "-c", "docker network inspect -f '{{json .IPAM.Config}}' kind | jq .[0]"]
  depends_on = [
    kind_cluster.default
  ]
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kind_cluster_config_path)
  }
}

resource "local_file" "metallb_config" {
  content = templatefile("${path.module}/metallb.config.crd.tmpl",
    {
      metallb_ip_range = var.metallb_ip_range
    }
  )
  filename   = "${path.module}/metallb.config.crd.yaml"
  depends_on = [helm_release.metallb]
}

resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  namespace        = "metallb-system"
  version          = "0.14.8"
  create_namespace = true
  timeout          = 300

  depends_on = [kind_cluster.default]
}

resource "null_resource" "wait_for_metallb" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      kubectl apply -f "${path.module}/metallb.config.crd.yaml"
      printf "\nWaiting for the metallb controller...\n"
      kubectl wait --namespace ${helm_release.metallb.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=speaker \
        --timeout=90s
    EOF
  }

  depends_on = [helm_release.metallb, local_file.metallb_config]
}

###--- Nginx Ingress 
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_helm_version

  namespace        = var.ingress_nginx_namespace
  create_namespace = true
  timeout = 300

  values = [
    <<EOT
controller:
  updateStrategy:
    type: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 1
  hostPort:
    enabled: true
  terminationGracePeriodSeconds: 0
  service:
    type: "LoadBalancer"
  watchIngressWithoutClass: true

  publishService:
    enabled: false
  extraArgs:
    publish-status-address: "localhost"
EOT
  ]
  depends_on = [helm_release.metallb]
}

resource "null_resource" "wait_for_ingress_nginx" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the nginx ingress controller...\n"
      kubectl wait --namespace ${helm_release.ingress_nginx.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    EOF
  }

  depends_on = [helm_release.ingress_nginx]
}


###---ArgoCD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "8.5.3" # Check for latest version if needed
  create_namespace = true

  cleanup_on_fail = true
  dependency_update = true

  values = [
    <<EOT
crds:
  install: true   # install CRDs with the chart
  keep: false     # remove CRDs on helm uninstall
  
server:
  service:
    type: ClusterIP  # or NodePort/ClusterIP as needed
  extraArgs:
    - --insecure  # only for development

configs:
  secret:
    argocdServerAdminPassword: "$2a$10$lgcvwdvggWeLl1AN14NWsePcWQczWHRQH2eiUNL9w/gN6NaelDl.G"  # Optional password override

   EOT
  ]
  depends_on = [helm_release.ingress_nginx]
}

resource "null_resource" "wait_for_argocd" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the argocd controller will be installed...\n"
      kubectl wait --namespace ${helm_release.argocd.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=server \
        --timeout=60s
    EOF
  }
  depends_on = [helm_release.argocd]
}
