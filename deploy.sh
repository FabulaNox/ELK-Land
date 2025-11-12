#!/bin/bash
# Terraform-based ELK deployment with flags and options
# Usage: ./deploy.sh [OPTIONS] ENVIRONMENT
#
# ENVIRONMENT: local, dev, prod
# 
# OPTIONS:
#   --clean              Clean deployment (destroy + rebuild)
#   --clean-data         Remove persistent data directories  
#   --clean-docker       Remove Docker images and system cleanup
#   --force-rebuild      Force recreation of all resources
#   --no-confirm         Skip confirmation prompts
#   --use-tfvars         Use existing tfvars file (skip credential prompts)
#   --plan-only          Show plan without applying
#   --help               Show this help message

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
CLEAN=false
CLEAN_DATA=false
CLEAN_DOCKER=false
FORCE_REBUILD=false
NO_CONFIRM=false
PLAN_ONLY=false
INTERACTIVE=true
ENVIRONMENT=""

# Credential variables
ELASTIC_USERNAME=""
ELASTIC_PASSWORD=""
KIBANA_USERNAME=""
KIBANA_PASSWORD=""

# Help function
show_help() {
    echo -e "${BLUE}🚀 ELK Stack Terraform Deployment${NC}"
    echo "=================================="
    echo ""
    echo "Usage: $0 [OPTIONS] ENVIRONMENT"
    echo ""
    echo "ENVIRONMENTS:"
    echo "  local       Local development environment"
    echo "  dev         Development environment"
    echo "  prod        Production environment"
    echo ""
    echo "OPTIONS:"
    echo "  --clean              Clean deployment (destroy + rebuild with confirmation)"
    echo "  --clean-data         Remove persistent data directories"
    echo "  --clean-docker       Remove Docker images and system cleanup"
    echo "  --force-rebuild      Force recreation of all resources"
    echo "  --no-confirm         Skip confirmation prompts (auto-approve all actions)"
    echo "  --use-tfvars         Use existing tfvars file (skip credential prompts)"
    echo "  --plan-only          Show plan without applying"
    echo "  --help               Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 local                          # Deploy with interactive credential setup"
    echo "  $0 --use-tfvars local             # Deploy using existing local.tfvars"
    echo "  $0 --plan-only prod               # Plan production deployment"
    echo "  $0 --clean local                  # Clean deploy with interactive confirmations"
    echo "  $0 --clean --no-confirm local     # Clean deploy without prompts"
    echo "  $0 --clean-data --clean dev       # Full clean deploy with confirmations"
    echo "  $0 --force-rebuild prod           # Force rebuild production"
    echo ""
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --clean-data)
            CLEAN_DATA=true
            shift
            ;;
        --clean-docker)
            CLEAN_DOCKER=true
            shift
            ;;
        --force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        --no-confirm)
            NO_CONFIRM=true
            shift
            ;;
        --use-tfvars)
            INTERACTIVE=false
            shift
            ;;
        --plan-only)
            PLAN_ONLY=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        local|dev|prod)
            ENVIRONMENT=$1
            shift
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if environment is specified
if [ -z "$ENVIRONMENT" ]; then
    echo -e "${RED}❌ Error: Environment not specified${NC}"
    echo "Use: $0 [OPTIONS] ENVIRONMENT"
    echo "Available environments: local, dev, prod"
    echo "Use --help for more information"
    exit 1
fi

ENV_FILE="$ENVIRONMENT.tfvars"

# Function to prompt for credentials
prompt_for_credentials() {
    echo -e "${YELLOW}🔐 Interactive Credential Setup${NC}"
    echo "================================="
    echo ""
    
    # Elasticsearch credentials
    echo -e "${BLUE}Elasticsearch Configuration:${NC}"
    read -p "Elasticsearch username (default: elastic): " input
    ELASTIC_USERNAME=${input:-elastic}
    
    while true; do
        read -s -p "Elasticsearch password (min 8 chars): " ELASTIC_PASSWORD
        echo
        if [ ${#ELASTIC_PASSWORD} -ge 8 ]; then
            read -s -p "Confirm Elasticsearch password: " confirm_pass
            echo
            if [ "$ELASTIC_PASSWORD" = "$confirm_pass" ]; then
                break
            else
                echo -e "${RED}❌ Passwords don't match. Try again.${NC}"
            fi
        else
            echo -e "${RED}❌ Password too short. Minimum 8 characters required.${NC}"
        fi
    done
    
    echo ""
    
    # Kibana credentials  
    echo -e "${BLUE}Kibana Configuration:${NC}"
    read -p "Kibana username (default: kibana_system): " input
    KIBANA_USERNAME=${input:-kibana_system}
    
    while true; do
        read -s -p "Kibana password (min 8 chars): " KIBANA_PASSWORD
        echo
        if [ ${#KIBANA_PASSWORD} -ge 8 ]; then
            read -s -p "Confirm Kibana password: " confirm_pass
            echo
            if [ "$KIBANA_PASSWORD" = "$confirm_pass" ]; then
                break
            else
                echo -e "${RED}❌ Passwords don't match. Try again.${NC}"
            fi
        else
            echo -e "${RED}❌ Password too short. Minimum 8 characters required.${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Credentials configured successfully${NC}"
    echo -e "${BLUE}Elasticsearch User:${NC} $ELASTIC_USERNAME"
    echo -e "${BLUE}Kibana User:${NC} $KIBANA_USERNAME"
    echo ""
    
    # Ask if user wants to save credentials
    echo -e "${YELLOW}💾 Save Credentials Option${NC}"
    read -p "Save these credentials to $ENV_FILE for future use? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create/update tfvars file with new credentials
        save_credentials_to_tfvars
        echo -e "${GREEN}✅ Credentials saved to $ENV_FILE${NC}"
        echo ""
    else
        echo -e "${YELLOW}⏭️  Using credentials for this deployment only${NC}"
        echo ""
    fi
}

# Function to save credentials to tfvars file  
save_credentials_to_tfvars() {
    # Create a backup if file exists
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "${ENV_FILE}.backup"
    fi
    
    # Create new tfvars file with current credentials and default settings
    cat > "$ENV_FILE" << EOF
# ${ENVIRONMENT^} Environment Configuration
# Generated on $(date)
# Use: terraform apply -var-file="$ENV_FILE"

# Security Configuration
elastic_username = "$ELASTIC_USERNAME"
elastic_password = "$ELASTIC_PASSWORD"  
kibana_username  = "$KIBANA_USERNAME"
kibana_password  = "$KIBANA_PASSWORD"

# Default settings for $ENVIRONMENT environment
es_java_opts = "-Xms2g -Xmx2g"
ls_java_opts = "-Xms1g -Xmx1g"

# Port Configuration
es_port     = 9200
kibana_port = 5601
syslog_port = 1514
EOF

    # Adjust memory settings based on environment
    if [ "$ENVIRONMENT" = "dev" ]; then
        sed -i 's/es_java_opts = "-Xms2g -Xmx2g"/es_java_opts = "-Xms1g -Xmx1g"/' "$ENV_FILE"
        sed -i 's/ls_java_opts = "-Xms1g -Xmx1g"/ls_java_opts = "-Xms512m -Xmx512m"/' "$ENV_FILE"
        sed -i "1s/.*/# Development Environment Configuration/" "$ENV_FILE"
    elif [ "$ENVIRONMENT" = "prod" ]; then
        sed -i 's/es_java_opts = "-Xms2g -Xmx2g"/es_java_opts = "-Xms4g -Xmx4g"/' "$ENV_FILE"
        sed -i 's/ls_java_opts = "-Xms1g -Xmx1g"/ls_java_opts = "-Xms2g -Xmx2g"/' "$ENV_FILE"
        sed -i "1s/.*/# Production Environment Configuration/" "$ENV_FILE"
    fi
}

# Function to load credentials from tfvars file
load_credentials_from_tfvars() {
    echo -e "${YELLOW}📋 Loading credentials from $ENV_FILE${NC}"
    
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}❌ Error: $ENV_FILE not found${NC}"
        if [ "$INTERACTIVE" = false ]; then
            echo "Use --help for usage information or run without --use-tfvars for interactive setup"
        fi
        exit 1
    fi
    
    # Extract values from tfvars file
    ELASTIC_USERNAME=$(grep "elastic_username" "$ENV_FILE" | cut -d'"' -f2)
    ELASTIC_PASSWORD=$(grep "elastic_password" "$ENV_FILE" | cut -d'"' -f2)
    KIBANA_USERNAME=$(grep "kibana_username" "$ENV_FILE" | cut -d'"' -f2)
    KIBANA_PASSWORD=$(grep "kibana_password" "$ENV_FILE" | cut -d'"' -f2)
    
    # Check if all credentials were found
    if [ -z "$ELASTIC_USERNAME" ] || [ -z "$ELASTIC_PASSWORD" ] || [ -z "$KIBANA_USERNAME" ] || [ -z "$KIBANA_PASSWORD" ]; then
        echo -e "${RED}❌ Error: Missing credentials in $ENV_FILE${NC}"
        echo "Required variables: elastic_username, elastic_password, kibana_username, kibana_password"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Credentials loaded from $ENV_FILE${NC}"
    echo -e "${BLUE}Elasticsearch User:${NC} $ELASTIC_USERNAME"
    echo -e "${BLUE}Kibana User:${NC} $KIBANA_USERNAME"
    echo ""
}

echo -e "${GREEN}🚀 ELK Stack Terraform Deployment${NC}"
echo "=================================="
echo -e "${BLUE}Environment:${NC} $ENVIRONMENT ($ENV_FILE)"
echo -e "${BLUE}Clean deployment:${NC} $CLEAN"
echo -e "${BLUE}Clean data:${NC} $CLEAN_DATA" 
echo -e "${BLUE}Clean Docker:${NC} $CLEAN_DOCKER"
echo -e "${BLUE}Force rebuild:${NC} $FORCE_REBUILD"
echo -e "${BLUE}Interactive credentials:${NC} $INTERACTIVE"
echo -e "${BLUE}Plan only:${NC} $PLAN_ONLY"
echo ""

# Handle credentials
if [ "$INTERACTIVE" = true ]; then
    # Check if tfvars file exists for loading credentials
    if [ -f "$ENV_FILE" ]; then
        load_credentials_from_tfvars
    else
        prompt_for_credentials
    fi
else
    load_credentials_from_tfvars
fi

# Confirmation prompt (skip if we're doing a clean deployment - it has its own prompts)
if [ "$NO_CONFIRM" = false ] && [ "$PLAN_ONLY" = false ] && [ "$CLEAN" = false ]; then
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
fi

# Clean Docker if requested
if [ "$CLEAN_DOCKER" = true ]; then
    echo -e "${YELLOW}🐳 Cleaning Docker containers and images...${NC}"
    docker stop elasticsearch kibana logstash 2>/dev/null || true
    docker rm elasticsearch kibana logstash 2>/dev/null || true
    docker network rm elk_network 2>/dev/null || true
    
    # Remove ELK images
    docker rmi docker.elastic.co/elasticsearch/elasticsearch:8.15.0 2>/dev/null || true
    docker rmi docker.elastic.co/kibana/kibana:8.15.0 2>/dev/null || true
    docker rmi docker.elastic.co/logstash/logstash:8.15.0 2>/dev/null || true
    
    docker system prune -f
    docker volume prune -f
    echo -e "${GREEN}✅ Docker cleanup complete${NC}"
fi

# Clean data directories if requested
if [ "$CLEAN_DATA" = true ]; then
    echo -e "${YELLOW}🗂️  Cleaning persistent data directories...${NC}"
    if [ "$NO_CONFIRM" = false ]; then
        read -p "⚠️  This will delete ALL ELK data. Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}⏭️  Skipping data cleanup${NC}"
        else
            sudo rm -rf data/elasticsearch/* 2>/dev/null || true
            sudo rm -rf data/kibana/* 2>/dev/null || true 
            sudo rm -rf data/logstash/* 2>/dev/null || true
            echo -e "${GREEN}✅ Data directories cleaned${NC}"
        fi
    else
        sudo rm -rf data/elasticsearch/* 2>/dev/null || true
        sudo rm -rf data/kibana/* 2>/dev/null || true
        sudo rm -rf data/logstash/* 2>/dev/null || true
        echo -e "${GREEN}✅ Data directories cleaned${NC}"
    fi
fi

# Terraform operations
echo -e "${YELLOW}⚙️  Initializing Terraform...${NC}"
terraform init

# Build terraform command with credentials
TERRAFORM_ARGS="-var elastic_username=\"$ELASTIC_USERNAME\" -var elastic_password=\"$ELASTIC_PASSWORD\" -var kibana_username=\"$KIBANA_USERNAME\" -var kibana_password=\"$KIBANA_PASSWORD\""

# Add other variables from tfvars file if using interactive mode
if [ "$INTERACTIVE" = true ]; then
    # Extract other variables from tfvars file
    if grep -q "es_java_opts" "$ENV_FILE"; then
        ES_JAVA_OPTS=$(grep "es_java_opts" "$ENV_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/')
        TERRAFORM_ARGS="$TERRAFORM_ARGS -var es_java_opts=\"$ES_JAVA_OPTS\""
    fi
    if grep -q "ls_java_opts" "$ENV_FILE"; then
        LS_JAVA_OPTS=$(grep "ls_java_opts" "$ENV_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/')
        TERRAFORM_ARGS="$TERRAFORM_ARGS -var ls_java_opts=\"$LS_JAVA_OPTS\""
    fi
    if grep -q "es_port" "$ENV_FILE"; then
        ES_PORT=$(grep "es_port" "$ENV_FILE" | grep -o '[0-9]*')
        TERRAFORM_ARGS="$TERRAFORM_ARGS -var es_port=$ES_PORT"
    fi
    if grep -q "kibana_port" "$ENV_FILE"; then
        KIBANA_PORT=$(grep "kibana_port" "$ENV_FILE" | grep -o '[0-9]*')
        TERRAFORM_ARGS="$TERRAFORM_ARGS -var kibana_port=$KIBANA_PORT"
    fi
    if grep -q "syslog_port" "$ENV_FILE"; then
        SYSLOG_PORT=$(grep "syslog_port" "$ENV_FILE" | grep -o '[0-9]*')
        TERRAFORM_ARGS="$TERRAFORM_ARGS -var syslog_port=$SYSLOG_PORT"
    fi
else
    # Use the entire tfvars file
    TERRAFORM_ARGS="-var-file=\"$ENV_FILE\""
fi

# Add force rebuild options
if [ "$FORCE_REBUILD" = true ]; then
    TERRAFORM_ARGS="$TERRAFORM_ARGS -replace=docker_container.elasticsearch"
    TERRAFORM_ARGS="$TERRAFORM_ARGS -replace=docker_container.kibana" 
    TERRAFORM_ARGS="$TERRAFORM_ARGS -replace=docker_container.logstash"
fi

# Clean deployment (destroy first)
if [ "$CLEAN" = true ] && [ "$PLAN_ONLY" = false ]; then
    echo -e "${YELLOW}🗑️  Clean Deployment: Destroying existing infrastructure...${NC}"
    
    if [ "$NO_CONFIRM" = false ]; then
        echo ""
        echo -e "${RED}⚠️  WARNING: This will destroy ALL existing ELK containers and resources!${NC}"
        echo -e "${YELLOW}📋 Current infrastructure will be completely removed before rebuilding.${NC}"
        echo ""
        read -p "🤔 Do you want to continue with clean deployment? (y/N): " -n 1 -r
        echo
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}⏭️  Clean deployment cancelled. Use regular deployment instead.${NC}"
            CLEAN=false
        else
            echo -e "${GREEN}✅ Proceeding with clean deployment...${NC}"
            if [ "$INTERACTIVE" = true ]; then
                eval "terraform destroy $TERRAFORM_ARGS -auto-approve" || echo "No existing infrastructure found"
            else
                terraform destroy -var-file="$ENV_FILE" -auto-approve || echo "No existing infrastructure found"
            fi
        fi
    else
        # No confirmation mode - proceed directly
        if [ "$INTERACTIVE" = true ]; then
            eval "terraform destroy $TERRAFORM_ARGS -auto-approve" || echo "No existing infrastructure found"
        else
            terraform destroy -var-file="$ENV_FILE" -auto-approve || echo "No existing infrastructure found"
        fi
    fi
fi

# Plan or Apply
if [ "$PLAN_ONLY" = true ]; then
    echo -e "${YELLOW}📋 Generating Terraform plan...${NC}"
    if [ "$INTERACTIVE" = true ]; then
        eval "terraform plan $TERRAFORM_ARGS"
    else
        terraform plan -var-file="$ENV_FILE"
    fi
else
    echo -e "${YELLOW}🚀 Applying Terraform configuration...${NC}"
    
    # Add extra confirmation for clean deployments
    if [ "$CLEAN" = true ] && [ "$NO_CONFIRM" = false ]; then
        echo ""
        echo -e "${BLUE}📋 Ready to rebuild ELK stack with new configuration...${NC}"
        read -p "🚀 Proceed with deployment? (Y/n): " -n 1 -r
        echo
        echo
        
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}⏭️  Deployment cancelled.${NC}"
            exit 0
        fi
    fi
    
    if [ "$INTERACTIVE" = true ]; then
        eval "terraform apply $TERRAFORM_ARGS -auto-approve"
    else
        terraform apply -var-file="$ENV_FILE" -auto-approve
    fi
    
    # Wait for services
    echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
    sleep 20
    
    # Verification
    echo -e "${YELLOW}🔍 Verifying deployment...${NC}"
    
    # Get ports from Terraform output
    ES_URL=$(terraform output -raw elasticsearch_url 2>/dev/null || echo "http://localhost:9200")
    KIBANA_URL=$(terraform output -raw kibana_url 2>/dev/null || echo "http://localhost:5601")
    
    echo "Elasticsearch: $ES_URL"
    echo "Kibana: $KIBANA_URL"
    
    # Test services
    if curl -s "$ES_URL" > /dev/null; then
        echo -e "${GREEN}✅ Elasticsearch is running${NC}"
    else
        echo -e "${RED}❌ Elasticsearch is not responding${NC}"
    fi
    
    if curl -s "$KIBANA_URL" > /dev/null; then
        echo -e "${GREEN}✅ Kibana is running${NC}"
    else
        echo -e "${RED}❌ Kibana is not responding${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Deployment complete!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Access Information:${NC}"
    echo "• Elasticsearch: $ES_URL"
    echo "• Kibana: $KIBANA_URL"
    echo "• Syslog Port: 1514 (UDP/TCP)"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "1. Access Kibana at: $KIBANA_URL"
    echo "2. Use credentials from $ENV_FILE"
    echo "3. Configure data sources and dashboards"
fi