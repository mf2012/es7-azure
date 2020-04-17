variable "azure_location" {
  type = string

  # Azure specific
  # Best prices for B1MS as of june 2019:
  #    'East US' < 'West US2' == 'North Central US' < Other US
  #    'Canada Central' < 'Canada East'
  default = "West US"
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "es_cluster" {
  description = "Name of the elasticsearch cluster, used in node discovery"
  default     = "my-cluster"
}

variable "key_path" {
  description = "Key name to be used with the launched instances."
  default     = "~/.ssh/id_rsa.pub"
}

variable "priv_key_path" {
  description = "Key name to use for provider connections."
  default     = "~/.ssh/id_rsa"
}

variable "environment" {
  default = "default"
}

variable "instance_type" {
  type    = string
  default = "Standard_D2s_v2"
}

variable "elasticsearch_volume_size" {
  type    = string
  default = "100" # gb
}

variable "use_instance_storage" {
  default = "true"
}

variable "associate_public_ip" {
  default = "true"
}

variable "node_count" {
  default = "3"
}

# whether or not to enable x-pack security on the cluster
variable "security_enabled" {
  default = "false"
}

# whether or not to enable x-pack monitoring on the cluster
variable "monitoring_enabled" {
  default = "true"
}

# client nodes have nginx installed on them, these credentials are used for basic auth
variable "client_user" {
  default = "exampleuser"
}

variable "xpack_monitoring_host" {
  description = "ES host to send monitoring data"
  default     = "self"
}

variable "tags" {
}
