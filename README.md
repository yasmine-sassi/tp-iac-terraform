# Infrastructure as Code - Terraform Docker Deployment

Automated deployment of a web application (Nginx) and PostgreSQL database using Terraform and Docker. This project includes both local deployment and GitHub Actions CI/CD pipeline.

## 📋 Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Local Deployment](#local-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Outputs](#outputs)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Overview

This Infrastructure as Code project demonstrates:
- **Terraform** for infrastructure orchestration
- **Docker** for containerization (Nginx web server + PostgreSQL database)
- **GitHub Actions** for automated CI/CD deployments
- **Cross-platform support** (Windows & Linux)

### Architecture
```
┌─────────────────────────────────────────┐
│         GitHub Actions CI/CD            │
│  (Automated on push to main branch)      │
└─────────────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │    Terraform Apply    │
        └───────────────────────┘
                    ↓
        ┌─────────────┬──────────┐
        ↓             ↓          ↓
   Docker Build  Build Nginx  PostgreSQL
   (local-exec)  Container    Container
                    ↓             ↓
            Port 8080         Port 5432
                (Web)        (Database)
```

## Prerequisites

### Local Deployment
- **Terraform** ≥ 1.0 ([Install](https://www.terraform.io/downloads))
- **Docker Desktop** (Windows) or **Docker Engine** (Linux/Mac)
  - Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Linux: `apt-get install docker.io`
- **PowerShell** (Windows) or **Bash** (Linux/Mac)

### CI/CD Pipeline
- **GitHub Account** with repository access
- **Repository Secrets** configured (see CI/CD section)

## Local Deployment

### Step 1: Initialize Terraform

Download and initialize the Docker provider:

```powershell
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of kreuzwerker/docker from the dependency lock file
- Using hashicorp/null v3.2.4
Terraform has been successfully initialized!
```

### Step 2: Configure Variables

Create a local variables file (already in `.gitignore`):

```powershell
# Windows PowerShell
@"
db_password = "your_secure_password_here"
"@ | Set-Content -Path terraform.tfvars
```

Or edit `terraform.tfvars` directly with:
```hcl
db_password = "your_secure_password_here"
```

### Step 3: Review the Plan

Simulate the infrastructure changes without making them:

```powershell
terraform plan
```

**Expected output:**
```
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_access_url     = "http://localhost:8080"
  + db_connection_info = "postgresql://devops_user@localhost:5432/devops_db"
  + db_container_name  = "tp-db-postgres"
```

### Step 4: Deploy Infrastructure

Apply the Terraform configuration to create all resources:

```powershell
terraform apply -auto-approve
```

**What gets created:**
- `tp-web-app:latest` Docker image (Nginx)
- `tp-app-web` Docker container (port 8080)
- PostgreSQL container `tp-db-postgres` (port 5432)
- Terraform state files

### Step 5: Validate Deployment

Test the web application:

```powershell
# Test web server
curl http://localhost:8080/

# View running containers
docker ps

# Check PostgreSQL connection
docker exec tp-db-postgres psql -U devops_user -d devops_db -c "\l"
```

**Expected curl response:**
```html
<!doctype html>
<html>
  <head>
    <title>IaC Demo</title>
  </head>
  <body>
    <h1>Application Deployed via Terraform IaC!</h1>
    <p>Infrastructure as Code — INSAT GL4</p>
  </body>
</html>
```

### Step 6: Cleanup

Remove all resources when done:

```powershell
terraform destroy -auto-approve
```

## CI/CD Pipeline

### GitHub Actions Workflow Overview

The workflow automatically deploys infrastructure on every push to the `main` branch.

**File:** `.github/workflows/terraform.yml`

**Workflow Steps:**
1. Checkout repository code
2. Setup Terraform
3. Initialize Terraform
4. Run `terraform plan` (validation)
5. Run `terraform apply` (deployment on main branch)

### Setup Instructions

#### 1. Set GitHub Secrets

Navigate to your repository on GitHub:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Create secret:
   - **Name:** `DB_PASSWORD`
   - **Value:** Your secure database password

#### 2. Push to Trigger Workflow

```powershell
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

#### 3. Monitor Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select the latest workflow run
4. View logs in real-time

**Workflow logs will show:**
```
✓ Checkout
✓ Setup Terraform
✓ Terraform Init
✓ Terraform Plan
✓ Terraform Apply (on main branch only)
```

### Workflow Features

- **Auto-detecting Docker provider**: Works on both Windows (npipe) and Linux (unix socket)
- **Secure credentials**: Password passed via GitHub Secrets, not in code
- **Plan before apply**: Always shows changes before deploying
- **Conditional apply**: Only applies changes on `main` branch pushes
- **Cross-platform**: Runs successfully on GitHub's Linux runners

## Project Structure

```
tp-iac-local/
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitHub Actions CI/CD pipeline
├── main.tf                         # Main Terraform configuration
├── variables.tf                    # Variable definitions
├── outputs.tf                      # Output definitions
├── Dockerfile_app                  # Nginx container definition
├── index.html                      # Web content
├── terraform.tfvars               # Local variables (git ignored)
├── terraform.tfstate              # Current state (git ignored)
├── terraform.tfstate.backup       # State backup (git ignored)
├── .gitignore                      # Files to ignore in git
└── README.md                       # This file
```

## Configuration

### Variables

**File:** `variables.tf`

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `db_name` | string | `devops_db` | PostgreSQL database name |
| `db_user` | string | `devops_user` | PostgreSQL username |
| `db_password` | string | *None* | PostgreSQL password (required, sensitive) |
| `app_port_external` | number | `8080` | External port for web application |

### Outputs

**File:** `outputs.tf`

After deployment, Terraform outputs:

```hcl
app_access_url      = "http://localhost:8080"
db_connection_info  = "postgresql://devops_user@localhost:5432/devops_db"
db_container_name   = "tp-db-postgres"
```

View outputs anytime:
```powershell
terraform output
```

## Security

### Best Practices Implemented

✅ **No Hardcoded Credentials**
- Database password not stored in code
- Local: Use `terraform.tfvars` (in `.gitignore`)
- CI/CD: Use GitHub Secrets

✅ **Sensitive Values**
- Password marked as `sensitive = true` in variables
- Terraform masks in logs

✅ **Ignore File**
```
# Ignored files (not committed to git)
*.tfvars
*.tfvars.json
terraform.tfstate*
.env
```

✅ **Cross-Platform Provider**
- Docker provider auto-detects socket location
- Works securely on Windows and Linux

### Credential Management

**Local deployment:**
```powershell
# Create terraform.tfvars (not versioned)
db_password = "your_secure_password"
```

**GitHub Actions:**
```yaml
# In workflow, accessed securely
env:
  TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
```

## Troubleshooting

### Error: "protocol not available" (GitHub Actions)

**Cause:** Docker provider misconfigured for Linux runner

**Solution:** Already fixed in this repo - provider auto-detects socket

### Error: "failed to read dockerfile: unexpected EOF" (Windows)

**Cause:** Line ending issues with Dockerfile

**Solution:** Ensure Dockerfile has proper UTF-8 encoding and Unix line endings (LF)

### Containers not running after apply

**Check:**
```powershell
# List all containers
docker ps -a

# View container logs
docker logs tp-app-web
docker logs tp-db-postgres

# Inspect state
terraform show
```

### Port already in use (8080 or 5432)

**Solution:** Either:
1. Stop other services using those ports
2. Modify `variables.tf` and use different ports:
   ```hcl
   app_port_external = 9090  # Use 9090 instead of 8080
   ```

### Can't connect to database

**Test connection:**
```powershell
docker exec tp-db-postgres psql -U devops_user -d devops_db -c "SELECT version();"
```

**Expected output:**
```
PostgreSQL X.X on ...
```

## Common Commands

```powershell
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan

# Apply changes
terraform apply -auto-approve

# Show outputs
terraform output

# Show specific output
terraform output app_access_url

# Destroy all resources
terraform destroy -auto-approve

# View state
terraform show

# Refresh state
terraform refresh
```

## Docker Commands

```powershell
# List running containers
docker ps

# List all containers
docker ps -a

# View container logs
docker logs tp-app-web
docker logs tp-db-postgres

# Execute command in container
docker exec tp-db-postgres psql -U devops_user

# Stop containers
docker stop tp-app-web tp-db-postgres

# Remove containers
docker rm tp-app-web tp-db-postgres

# Remove images
docker rmi tp-web-app:latest postgres:latest
```

## Support & Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [kreuzwerker/docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Docker Documentation](https://docs.docker.com)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Last Updated:** April 23, 2026
