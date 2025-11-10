# JVM options
variable "es_java_opts" {
  type        = string
  description = "Java Virtual Machine options for Elasticsearch"
  default     = "-Xms2g -Xmx2g"
}

variable "ls_java_opts" {
  type        = string
  description = "Java Virtual Machine options for Logstash"
  default     = "-Xms1g -Xmx1g"
}

# Ports
variable "es_port" {
  type        = number
  description = "External port for Elasticsearch"
  default     = 9200
}

variable "kibana_port" {
  type        = number
  description = "External port for Kibana"
  default     = 5601
}

variable "syslog_port" {
  type        = number
  description = "Port for Logstash syslog input (UDP/TCP)"
  default     = 1514
}

# Paths (absolute paths required for Docker bind mounts)
variable "es_data_path" {
  type        = string
  description = "Absolute path for Elasticsearch data directory"
  default     = ""
}

variable "logstash_data_path" {
  type        = string
  description = "Absolute path for Logstash data directory"
  default     = ""
}

variable "kibana_data_path" {
  type        = string
  description = "Absolute path for Kibana data directory"
  default     = ""
}

variable "logstash_config_path" {
  type        = string
  description = "Absolute path for Logstash configuration directory"
  default     = ""
}