terraform {
  required_version = ">= 1.9.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Shared network for ELK stack
resource "docker_network" "elk" {
  name = "elk_network"
}

# Elasticsearch with RBAC enabled
resource "docker_image" "elasticsearch" {
  name         = "docker.elastic.co/elasticsearch/elasticsearch:8.15.0"
  keep_locally = true
}

resource "docker_container" "elasticsearch" {
  name    = "elasticsearch"
  image   = docker_image.elasticsearch.name
  restart = "unless-stopped"

  env = [
    "discovery.type=single-node", 
    "ES_JAVA_OPTS=${var.es_java_opts}",
    "xpack.security.enabled=true",
    "ELASTIC_PASSWORD=changeme"
  ]

  ports {
    internal = 9200
    external = var.es_port
  }
  ports {
    internal = 9300
    external = 9300
  }

  networks_advanced {
    name    = docker_network.elk.name
    aliases = ["elasticsearch"]
  }

  mounts {
    target = "/usr/share/elasticsearch/data"
    source = abspath("data/elasticsearch")
    type   = "bind"
  }
}

# Set kibana_system password after Elasticsearch is ready
resource "null_resource" "setup_kibana_user" {
  provisioner "local-exec" {
    command = <<-EOF
      # Wait for Elasticsearch to be ready
      until curl -s http://elastic:changeme@localhost:${var.es_port}/_cluster/health > /dev/null; do
        echo "Waiting for Elasticsearch to be ready..."
        sleep 5
      done
      
      # Set kibana_system password
      curl -X POST "http://elastic:changeme@localhost:${var.es_port}/_security/user/kibana_system/_password" \
           -H "Content-Type: application/json" \
           -d '{"password": "changeme"}'
    EOF
  }

  depends_on = [docker_container.elasticsearch]
}

# Kibana with RBAC
resource "docker_image" "kibana" {
  name         = "docker.elastic.co/kibana/kibana:8.15.0"
  keep_locally = true
}

resource "docker_container" "kibana" {
  name    = "kibana"
  image   = docker_image.kibana.name
  restart = "unless-stopped"

  env = [
    "ELASTICSEARCH_HOSTS=http://elasticsearch:9200",
    "ELASTICSEARCH_USERNAME=kibana_system", 
    "ELASTICSEARCH_PASSWORD=changeme"
  ]

  ports {
    internal = 5601
    external = var.kibana_port
  }

  networks_advanced {
    name    = docker_network.elk.name
    aliases = ["kibana"]
  }

  mounts {
    target = "/usr/share/kibana/data"
    source = abspath("data/kibana")
    type   = "bind"
  }

  depends_on = [docker_container.elasticsearch, null_resource.setup_kibana_user]
}

# Logstash
resource "docker_image" "logstash" {
  name         = "docker.elastic.co/logstash/logstash:8.15.0"
  keep_locally = true
}

resource "docker_container" "logstash" {
  name    = "logstash"
  image   = docker_image.logstash.name
  restart = "unless-stopped"

  ports {
    internal = var.syslog_port
    external = var.syslog_port
    protocol = "udp"
  }
  ports {
    internal = var.syslog_port
    external = var.syslog_port
    protocol = "tcp"
  }

  networks_advanced {
    name    = docker_network.elk.name
    aliases = ["logstash"]
  }

  # Mount the entire pipeline directory for flexibility
  mounts {
    target = "/usr/share/logstash/pipeline"
    source = abspath("conf")
    type   = "bind"
  }

  env = [
    "LS_JAVA_OPTS=${var.ls_java_opts}"
  ]

  depends_on = [docker_container.elasticsearch]
}