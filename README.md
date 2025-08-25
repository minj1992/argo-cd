Perfect 👍 — let’s add a clean **index (table of contents)** at the top of your `README.md` so anyone can easily navigate it.

Here’s the updated README with an **index** included:

---

# 🚀 Kubernetes Platform Setup with ArgoCD & Ingress-NGINX

## 📑 Index

1. [Install](#-install)

   * [Add Repos](#add-repos-only-once)
   * [Install ingress-nginx](#install-ingress-nginx-using-your-plateformyaml)
   * [Install ArgoCD](#install-argo-cd-using-your-install-argo-cd-helm-valueyaml)
2. [Uninstall](#%EF%B8%8F-uninstall)
3. [Application Deployment](#-application-deployment)
4. [Infrastructure Setup (EKS with Terraform)](#-infrastructure-setup-eks-with-terraform)
5. [Architecture](#-architecture)

   * [Infra Text Diagram](#infra-text-based-diagram)
   * [Application Infra](#application-infra-in-eks)
   * [Cluster Application Architecture](#application-architecture-in-cluster)

---

## 🚀 Install

### Add repos (only once)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### Install ingress-nginx (using your plateform.yaml)

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f platform/ingress-nginx/values.yaml
```

### Install argo-cd (using your install-argo-cd-helm-value.yaml)

```bash
kubectl apply -f argo/argocd-namespace.yaml
helm upgrade --install argocd argo/argo-cd -n argocd -f argo/install-argocd-helm-values.yaml
```

Post Argo CD install:

```bash
kubectl get ingress -A
kubectl apply -f argo/argocd-ingress.yaml
helm upgrade argocd argo/argo-cd -n argocd -f argo/install-argocd-helm-values.yaml
```

---

## 🗑️ Uninstall

```bash
helm uninstall argocd -n argocd
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete ns argocd ingress-nginx --ignore-not-found
```

✅ With this setup:

* `ingress-nginx` → namespace `ingress-nginx`
* `argocd` → namespace `argocd`
* Both use your provided values files.

---

## 📦 Application Deployment

To deploy your **Java Web App** via ArgoCD:

```bash
kubectl apply -f argo/argocd-apps/java-app-app.yaml -n argocd
```

---

## 🏗️ Infrastructure Setup (EKS with Terraform)

1. Go to the `eks/` folder.
2. Replace your AWS `access_key` and `secret_key` in `terraform.tfvars` (or env variables).
3. Run:

   ```bash
   terraform init
   terraform apply -auto-approve
   ```
4. Once cluster is ready, update kubeconfig:

   ```bash
   aws eks update-kubeconfig --region <your-region> --name <cluster-name>
   ```

---

## 🏛️ Architecture

### Infra Text Based Diagram

```
AWS Account
   └── VPC
       ├── Public Subnets
       │    └── Internet Gateway
       ├── Private Subnets
       │    └── NAT Gateway
       └── EKS Cluster
            ├── Node Group(s)
            ├── ingress-nginx (Namespace: ingress-nginx)
            └── argocd (Namespace: argocd)
```

### Application Infra in EKS

```
EKS Cluster
   ├── ingress-nginx Controller
   ├── ArgoCD
   │    └── Manages deployments
   └── Java Web App (via ArgoCD Application CR)
```

### Application Architecture in Cluster

```
[User] --> [Route53 DNS: A/CNAME Record] --> [AWS Load Balancer]
    --> [Ingress NGINX Controller] --> [ArgoCD-managed App Services]
```

---

Would you like me to also add **screenshots placeholders** (like `![diagram](./images/eks-arch.png)`) so you or your team can later drop actual diagrams, or you want to keep it text-based only?
