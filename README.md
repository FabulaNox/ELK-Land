# ELK-Land 🚀

**A Production-Ready Terraform-Deployed ELK Stack for Modern Log Management**

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-Required-2496ED?logo=docker)](https://www.docker.com/)
[![Elasticsearch](https://img.shields.io/badge/Elasticsearch-8.15.0-005571?logo=elasticsearch)](https://www.elastic.co/elasticsearch/)
[![Kibana](https://img.shields.io/badge/Kibana-8.15.0-F04E98?logo=kibana)](https://www.elastic.co/kibana/)
[![Logstash](https://img.shields.io/badge/Logstash-8.15.0-005571?logo=logstash)](https://www.elastic.co/logstash/)

## 📋 Overview

ELK-Land is a comprehensive Infrastructure as Code (IaC) solution that deploys a full ELK (Elasticsearch, Logstash, Kibana) stack using Terraform and Docker. This project demonstrates modern DevOps practices with proper variable management, security considerations, and scalable architecture.

Perfect for **portfolios**, **learning environments**, and **small to medium production workloads**.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│    Logstash     │    │  Elasticsearch  │    │     Kibana      │
│   Port: 1514    │────│   Port: 9200    │────│   Port: 5601    │
│   (UDP/TCP)     │    │   (HTTP API)    │    │  (Web Interface)│
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │                 │
                    │  elk_network    │
                    │ (Docker Bridge) │
                    │                 │
                    └─────────────────┘
```

## ✨ Features

- 🏢 **Production-Ready**: RBAC enabled, persistent storage, proper networking
- 🔧 **Configurable**: Environment-specific variables via `terraform.tfvars`
- 🔒 **Secure**: Authentication enabled, gitignored sensitive configs
- 📊 **Scalable**: JVM tuning, resource management, modular design
- 🐳 **Containerized**: Docker-based deployment with proper orchestration
- 📝 **Documentation**: Comprehensive setup and usage guides

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.9.0
- [Docker](https://docs.docker.com/get-docker/) with daemon running
- 4GB+ available RAM (recommended for default JVM settings)

### 1. Clone and Setup

```bash
git clone https://github.com/yourusername/ELK-Land.git
cd ELK-Land
cp terraform.tfvars.example terraform.tfvars  # Create from example if needed
```

### 2. Deploy the Stack

```bash
terraform init
terraform plan
terraform apply
```

### 3. Access Services

- **Kibana**: http://localhost:5601 (`elastic` / `changeme`)
- **Elasticsearch**: http://localhost:9200
- **Logstash**: Send syslog to `localhost:1514` (UDP/TCP)

## ⚙️ Configuration

### Environment Variables (`terraform.tfvars`)

```hcl
# JVM Configuration
es_java_opts = "-Xms4g -Xmx4g"  # Elasticsearch heap
ls_java_opts = "-Xms2g -Xmx2g"  # Logstash heap

# Network Ports
es_port     = 9200
kibana_port = 5601
syslog_port = 1514

# Data Persistence Paths
es_data_path         = "./data/elasticsearch"
logstash_data_path   = "./data/logstash"
kibana_data_path     = "./data/kibana"
logstash_config_path = "./conf"
```

### Memory Recommendations

| Environment | Elasticsearch | Logstash | Total RAM |
|-------------|---------------|----------|-----------|
| Development | 2GB | 1GB | 4GB+ |
| Production | 4GB+ | 2GB+ | 8GB+ |
| Heavy Load | 8GB+ | 4GB+ | 16GB+ |

## 📊 Usage Examples

### Send Test Logs

```bash
# UDP Syslog
echo "<14>$(date '+%b %d %H:%M:%S') myhost myapp: Test log message" | nc -u localhost 1514

# TCP Syslog  
echo "<14>$(date '+%b %d %H:%M:%S') myhost myapp: Test log message" | nc localhost 1514

# Logger command (if available)
logger -n localhost -P 1514 "Test message from logger"
```

### Query Elasticsearch

```bash
# Check cluster health
curl http://elastic:changeme@localhost:9200/_cluster/health

# List indices
curl http://elastic:changeme@localhost:9200/_cat/indices

# Search logs
curl -X GET "elastic:changeme@localhost:9200/syslog-*/_search?q=*"
```

### Kibana Setup

1. Navigate to http://localhost:5601
2. Login with `elastic` / `changeme`
3. Go to **Stack Management** → **Index Patterns**
4. Create pattern: `syslog-*`
5. Select `@timestamp` as time field
6. Go to **Discover** to view logs

## 🗂️ Project Structure

```
ELK-Land/
├── main.tf                    # Main infrastructure definition
├── variables.tf               # Variable declarations
├── outputs.tf                 # Output definitions
├── terraform.tfvars          # Environment-specific values (gitignored)
├── conf/
│   └── logstash-pipeline.conf # Logstash processing pipeline
├── data/                      # Persistent data (gitignored)
│   ├── elasticsearch/
│   ├── kibana/
│   └── logstash/
└── .gitignore                 # Git exclusions
```

## 🔐 Security Considerations

### Default Credentials
⚠️ **Change default passwords before production use!**

- Elasticsearch: `elastic` / `changeme`
- Update passwords in `conf/logstash-pipeline.conf` and application configs

### Network Security
- All services isolated in Docker network
- Only necessary ports exposed to host
- Inter-service communication via container aliases

### Data Security
- Persistent volumes for data durability
- RBAC enabled on Elasticsearch
- Configuration files excluded from version control

## 🛠️ Operations

### Scaling Resources

```bash
# Update JVM settings in terraform.tfvars
es_java_opts = "-Xms8g -Xmx8g"
ls_java_opts = "-Xms4g -Xmx4g"

# Apply changes
terraform apply
```

### Backup Data

```bash
# Create backup directory
mkdir -p backups/$(date +%Y%m%d)

# Backup Elasticsearch data
sudo cp -r data/elasticsearch backups/$(date +%Y%m%d)/

# Backup Kibana dashboards via API
curl -X GET "elastic:changeme@localhost:9200/.kibana/_search?pretty" > backups/$(date +%Y%m%d)/kibana-config.json
```

### Clean Deployment

```bash
terraform destroy  # Remove containers and networks
sudo rm -rf data/*  # Clean persistent data (optional)
```

## 🐛 Troubleshooting

### Common Issues

**Container startup failures:**
```bash
# Check Docker logs
docker logs elasticsearch
docker logs logstash
docker logs kibana

# Verify Docker daemon
systemctl status docker
```

**Memory issues:**
```bash
# Check available memory
free -h

# Reduce JVM heap in terraform.tfvars
es_java_opts = "-Xms1g -Xmx1g"
```

**Port conflicts:**
```bash
# Check port usage
sudo netstat -tlnp | grep -E "(9200|5601|1514)"

# Update ports in terraform.tfvars if needed
```

### Performance Tuning

- **Elasticsearch**: Monitor cluster health and index sizes
- **Logstash**: Adjust batch sizes and workers in pipeline config
- **Kibana**: Enable caching and optimize queries

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test thoroughly
4. Commit changes (`git commit -m 'Add amazing feature'`)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Elastic](https://www.elastic.co/) for the amazing ELK stack
- [Terraform](https://www.terraform.io/) for Infrastructure as Code
- [Docker](https://www.docker.com/) for containerization platform

## 📧 Contact

**Your Name** - your.email@example.com

Project Link: [https://github.com/yourusername/ELK-Land](https://github.com/yourusername/ELK-Land)

---

⭐ If this project helped you, please consider giving it a star!