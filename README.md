# GKE Terraform Deployment with GitHub Actions

This repository contains Terraform configuration to deploy a minimal Google Kubernetes Engine (GKE) cluster on Google Cloud Platform using GitHub Actions for CI/CD.

## Architecture

- **GKE Cluster**: Single-zone private cluster in `us-central1-a`
- **VPC Network**: Custom VPC with private subnets
- **Node Pool**: Auto-scaling 1-3 x e2-medium instances with 12GB disk
- **NAT Gateway**: For private node internet access
- **Cloud Router**: For NAT Gateway routing

## Prerequisites

1. **Google Cloud Project** with billing enabled
2. **GitHub Repository** (public for free environment protection)
3. **GCS Bucket** for Terraform state: `github-actions-terraform-state-988`
4. **Workload Identity Federation** configured for OIDC authentication

## Setup

### 1. Google Cloud Setup

```bash
# Set project variables
export PROJECT_ID="vprofile-469703"
export PROJECT_NUMBER="175989535992"

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iamcredentials.googleapis.com

# Create GCS bucket for Terraform state
gsutil mb -p $PROJECT_ID -c STANDARD -l us-central1 gs://github-actions-terraform-state-988
```

### 2. Workload Identity Federation

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create github-pool-v2 \
  --location="global" \
  --description="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --workload-identity-pool="github-pool-v2" \
  --location="global" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='YOUR_GITHUB_USERNAME/action-gke-terraform'"

# Create Service Account
gcloud iam service-accounts create github-actions-sa \
  --description="GitHub Actions Service Account" \
  --display-name="GitHub Actions SA"

# Bind Service Account to Workload Identity
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool-v2/attribute.repository/YOUR_GITHUB_USERNAME/action-gke-terraform"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

### 3. GitHub Repository Setup

1. **Environment Protection**:
   - Go to Settings → Environments → Create `production` environment
   - Enable "Required reviewers" for manual approval

2. **Repository Variables**:
   ```
   DEPLOY_ENABLED=true    # Enable apply job
   DESTROY_ENABLED=false  # Disable destroy job by default
   ```

## Usage

### Deploy Infrastructure

1. **Push to main branch** (with `DEPLOY_ENABLED=true`):
   ```bash
   git add .
   git commit -m "Deploy GKE cluster"
   git push origin main
   ```

2. **Approve deployment** in GitHub Actions when prompted

### Destroy Infrastructure

1. **Set destroy variable**:
   ```bash
   # Set DESTROY_ENABLED=true in repository variables
   ```

2. **Manually trigger workflow**:
   - Go to Actions → Terraform GKE Deployment → Run workflow

3. **Approve destruction** when prompted

### Connect to Cluster

```bash
# Get cluster credentials
gcloud container clusters get-credentials vprofile-gke-cluster \
  --zone us-central1-a \
  --project vprofile-469703

# Verify connection
kubectl get nodes
```

## File Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf          # Output definitions
├── backend.tf          # Remote state configuration
├── .github/
│   └── workflows/
│       └── terraform-gke.yml  # GitHub Actions workflow
└── README.md           # This file
```

## Workflow Jobs

- **lint**: Terraform format and validation (PR only)
- **plan**: Generate execution plan (PR only)
- **apply**: Deploy infrastructure (main branch, manual approval)
- **destroy**: Destroy infrastructure (manual trigger, manual approval)
- **drift-check**: Daily infrastructure drift detection

## Troubleshooting

### Common Issues

1. **OIDC Authentication Failed**:
   - Verify project number (not project ID) in workload identity provider path
   - Check repository name in attribute condition

2. **Deletion Protection Error**:
   - Run `terraform apply` first to disable deletion protection
   - Then run `terraform destroy`

3. **Disk Size Too Small**:
   - GKE requires minimum 12GB disk for Container-Optimized OS
   - Update `disk_size_gb` in variables

4. **Machine Type Too Small**:
   - e2-micro is insufficient for GKE nodes
   - Use e2-small or larger

### Useful Commands

```bash
# Check cluster status
gcloud container clusters describe vprofile-gke-cluster --zone us-central1-a

# View node pool details
gcloud container node-pools describe vprofile-gke-cluster-node-pool \
  --cluster vprofile-gke-cluster --zone us-central1-a

# Manual Terraform operations
terraform init
terraform plan
terraform apply
terraform destroy
```

## Cost Optimization

- Single-zone deployment reduces cross-zone traffic costs
- e2-small instances are cost-effective for development
- Private cluster with NAT Gateway minimizes external IP costs
- Auto-scaling (1-3 nodes) provides flexibility while controlling costs

## Security Features

- Private GKE cluster (no public node IPs)
- Workload Identity Federation (no service account keys)
- Manual approval for infrastructure changes
- Encrypted Terraform state in GCS

## Contributing

1. Create feature branch
2. Make changes
3. Submit pull request
4. Review Terraform plan in PR
5. Merge to main for deployment