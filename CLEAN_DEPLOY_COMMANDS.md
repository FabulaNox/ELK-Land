# Manual Clean Deployment Commands
# ===================================

# 1. Destroy existing infrastructure
terraform destroy -var-file="<your-env>.tfvars" -auto-approve

# 2. Stop and remove containers
docker stop elasticsearch kibana logstash
docker rm elasticsearch kibana logstash

# 3. Remove Docker network
docker network rm elk_network

# 4. Clean Docker system (optional)
docker system prune -f
docker volume prune -f

# 5. Remove persistent data (CAUTION!)
sudo rm -rf data/elasticsearch/*
sudo rm -rf data/kibana/*
sudo rm -rf data/logstash/*

# 6. Redeploy with clean slate
terraform apply -var-file="<your-env>.tfvars" -auto-approve