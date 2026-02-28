<img width="1420" height="788" alt="image" src="https://github.com/user-attachments/assets/296dc4cd-8454-49b9-83f2-b28ddd25f352" />


## AWS EC2 | Knative
Knative Serving builds on Kubernetes to support deploying and serving of applications and functions as serverless containers. Serving is easy to get started with and scales to support advanced scenarios.


⭐  Architecture
```
✔️ Source Control (GitLab)
✔️ Infrastructure Orchestration Layer (Terraform Core)
✔️ Cloud Execution Layer → (AWS EC2)
✔️ Kubernetes Orchestration Layer (kind Cluster)
✔️ AI/ML Runtime Layer (LLM + Vector DB Stack) 
```

🚀 
```
terraform init
terraform validate
terraform plan -var-file="template.tfvars"
terraform apply -var-file="template.tfvars" -auto-approve
```

🧩 Config 
```
scp -i ~/.ssh/<your pem file> <your pem file> ec2-user@<terraform instance public ip>:/home/ec2-user
chmod 400 <your pem file>
```

