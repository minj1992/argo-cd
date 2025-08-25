

````markdown
# 🚀 Infrastructure & Application Setup on AWS EKS

This guide walks through:
1) Provisioning infra with **Terraform**
2) Configuring **AWS CLI** and connecting to EKS
3) Installing **Helm**
4) Installing **AWS EBS CSI Driver** (dynamic EBS volumes)
5) Installing **ingress-nginx** (Helm)
6) Installing **Argo CD** (Helm)
7) Deploying the **Java Web App** (Argo CD Application manifest)
8) Setting up **Route 53** with the Load Balancer

---

## 📑 Index
1. [Terraform Infrastructure Setup](#1-terraform-infrastructure-setup)
2. [AWS CLI Configuration & EKS Access](#2-aws-cli-configuration--eks-access)
3. [Install Helm](#3-install-helm)
4. [Install AWS EBS CSI Driver](#4-install-aws-ebs-csi-driver)
5. [Install ingress-nginx (Helm)](#5-install-ingress-nginx-helm)
6. [Install Argo CD (Helm)](#6-install-argo-cd-helm)
7. [Deploy Web Application (Argo CD)](#7-deploy-web-application-argo-cd)
8. [Route 53 & Load Balancer Setup](#8-route-53--load-balancer-setup)
9. [Uninstall / Cleanup](#9-uninstall--cleanup)

---

## 1) Terraform Infrastructure Setup
```bash
cd eks/
terraform init
terraform plan
terraform apply -auto-approve
````

---

## 2) AWS CLI Configuration & EKS Access

```bash
aws configure
aws eks --region <your-region> update-kubeconfig --name <your-cluster-name>
kubectl get nodes
```

---

## 3) Install Helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

---

## 4) Install AWS EBS CSI Driver

Create secret (using your AWS access key & secret key):

```bash
kubectl create secret generic aws-secret \
  --namespace kube-system \
  --from-literal "key_id=${AWS_ACCESS_KEY_ID}" \
  --from-literal "access_key=${AWS_SECRET_ACCESS_KEY}"
```

Add repo & install:

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm upgrade --install aws-ebs-csi-driver \
  --namespace kube-system \
  aws-ebs-csi-driver/aws-ebs-csi-driver
```

Verify:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

---

## 5) Install ingress-nginx (Helm)

Add repo (only once):

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

Install with your values file:

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f platform/ingress-nginx/values.yaml
```

Check service / external LB:

```bash
kubectl get svc -n ingress-nginx
```

---

## 6) Install Argo CD (Helm)

```bash
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argocd argo/argo-cd -n argocd \
  -f argo/install-argocd-helm-values.yaml
```

 Apply Argo CD ingress:

```bash
kubectl apply -f argo/argocd-ingress.yaml
kubectl get ingress -A
```

Get initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## 7) Deploy Web Application (Argo CD)

Use your **exact** Application manifest:

```bash
kubectl apply -f argo/argocd-apps/java-app-app.yaml -n argocd
```

Argo CD will reconcile the app defined in `charts/java-webapp`.

---

## 8) Route 53 & Load Balancer Setup

Get the LoadBalancer DNS (from ingress-nginx or your app’s Service/Ingress):

```bash
kubectl get svc -n ingress-nginx
kubectl get svc -n apps
kubectl get ingress -A
```

Create/Update a **Route 53** record:

* **A (Alias)** or **CNAME** → point to the LoadBalancer DNS, e.g.
  `devopslogs.com → k8s-xxxxxxxx.elb.amazonaws.com`

---

## 9) Uninstall / Cleanup

Uninstall Argo CD:

```bash
helm uninstall argocd -n argocd
kubectl delete ns argocd --ignore-not-found
```

Uninstall ingress-nginx:

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete ns ingress-nginx --ignore-not-found
```

(Optional) Uninstall EBS CSI Driver:

```bash
helm uninstall aws-ebs-csi-driver -n kube-system
```

Tear down infra (if desired):

```bash
cd eks/
terraform destroy -auto-approve
```
<img width="959" height="459" alt="00-argo" src="https://github.com/user-attachments/assets/1def4be3-60d4-4447-8c05-75ea809b510e" />



<img width="519" height="485" alt="001-argo" src="https://github.com/user-attachments/assets/bfe6b7a0-005a-44a6-8aac-874c652dd47c" />

<img width="910" height="479" alt="002-argo" src="https://github.com/user-attachments/assets/53a99f0a-03c5-4473-8810-d761fc58e0ec" />

<img width="936" height="392" alt="003-argo" src="https://github.com/user-attachments/assets/e0e62204-fc6d-464d-b0a6-35b1c8a4620a" />



```

