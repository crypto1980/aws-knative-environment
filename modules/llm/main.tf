
resource "helm_release" "anythingllm" {
  name             = "anythingllm"
  repository       = "https://la-cc.github.io/anything-llm-helm-chart"
  chart            = "anything-llm"
  namespace        = "anythingllm"
  create_namespace = true

  set {
    name  = "chromadb.enabled"
    value = "true"
  }

  set {
    name  = "config.VECTOR_DB"
    value = "chroma"
  }

  set {
    name  = "config.ADMIN_EMAIL"
    value = "admin@example.com"
  }

  set {
    name  = "config.ADMIN_PASSWORD"
    value = "SuperSecurePassword123!"
  }
}
