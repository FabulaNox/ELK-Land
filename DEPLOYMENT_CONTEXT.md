# ELK-Land Deployment Context

## Repository Principles

### "More is Less" Philosophy
This repository follows a **minimal, secure, and portable** deployment approach:
- ✅ **Zero personal data** in repository
- ✅ **No deployment artifacts** committed
- ✅ **Automated setup** requiring minimal user interaction
- ✅ **Portable across environments** without hardcoded paths

### What Should NEVER Be Committed

#### 🚫 Deployment Results
- `data/` - All runtime data directories (Elasticsearch, Kibana, Logstash)
- `.terraform.lock.hcl` - Provider lock files (environment-specific)
- `terraform.tfstate*` - State files (contain sensitive data)

#### 🚫 Personal Configuration
- `terraform.tfvars` - Personal variable overrides
- `.context.md` - Personal notes and context
- `SECURITY_AUDIT.md` - Security review artifacts

#### 🚫 Runtime Artifacts
- Container logs, SSL certificates, temporary files
- IDE/editor configurations, OS-generated files

### Deployment Guarantee
**No results of deployment are to be pushed to the repo.**

This ensures:
- 🔐 **Security**: No sensitive data exposure
- 🚀 **Portability**: Works across different environments
- 🧹 **Cleanliness**: Repository contains only source code
- 🔄 **Reproducibility**: Fresh deployments work consistently

### Quick Start
```bash
# Clone and deploy in one go:
git clone <repo-url>
cd terraform-elk
terraform init
terraform apply -auto-approve

# Access services:
# Elasticsearch: http://localhost:9200 (elastic:changeme)
# Kibana: http://localhost:5601 (kibana_system:changeme)
# Logstash: syslog on port 1514
```

### Automation Features
- ✅ **Automatic path resolution** with `abspath()`
- ✅ **Automatic Kibana user setup** via `null_resource`
- ✅ **Health checks** and dependency waiting
- ✅ **Zero manual configuration** required

---
*Last Updated: November 11, 2025*  
*Context: Post-automation implementation with full zero-interaction deployment*