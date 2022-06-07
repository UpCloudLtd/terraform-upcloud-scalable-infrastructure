variable "app_name" {
  type        = string
  description = "Name of your app. This will be used as a prefix for all of the resources titles."
  validation {
    condition = can(regex("^[a-zA-Z0-9_]*$", var.app_name))
    error_message = "App name should contain only alphanumeric characters."
  }
}

variable "zone" {
  type        = string
  description = "Zone for all of the resources."
}

variable "private_network_cidr" {
  type        = string
  description = "Private network IP address in CIDR notation (for example 10.0.42.0/24)."
  default     = "10.0.42.0/24"
}

variable "servers_count" {
  type        = number
  description = "Number of web servers you want to deploy."
  default     = 3
}

variable "servers_template" {
  type        = string
  description = "The template OS for your servers."
  default     = "Ubuntu Server 20.04 LTS (Focal Fossa)"
}

variable "servers_template_storage_size" {
  type        = number
  description = "Size of your OS template storage."
  default     = 25
}

variable "servers_plan" {
  type        = string
  description = "Simple plan for your web servers."
  default     = "2xCPU-4GB"
}

variable "servers_port" {
  type        = number
  description = "Port on which your web server listen for connections to serve your app."
}

variable "servers_ssh_keys" {
  type        = list(string)
  description = "List of SSH public keys that will be used to log into the web servers."
}

variable "servers_firewall_enabled" {
  type        = bool
  description = "Enables or disables firewall on the web servers."
  default     = false
}

variable "servers_allowed_remote_ips" {
  type        = list(string)
  description = "List of remote IP addresses that will be able to SSH into the web servers if the servers firewall is enabled."
  default     = []
}

variable "max_server_sessions" {
  type        = number
  description = "Maximum amount of sessions for single server before queueing."
  default     = 50000
}

variable "database_type" {
  type        = string
  description = "Database type. Can be PostgreSQL or MySQL."
  default     = "PostgreSQL"
  validation {
    condition     = anytrue([var.database_type == "PostgreSQL", var.database_type == "MySQL"])
    error_message = "Database type has to be either PostgreSQL or MySQL."
  }
}

variable "database_plan" {
  type        = string
  description = "Plan for your database service."
  default     = "2x2xCPU-4GB-100GB"
}

variable "domains" {
  type        = list(string)
  description = "List of domains for your app. All of the listed domains should have a CNAME record set that points towards the load balancer DNS name (see 'app_url' output value)."
}

variable "load_balancer_frontend_port" {
  type        = number
  description = "Port on which the load balancer will listen for requests."
  default     = 443
}

variable "load_balancer_plan" {
  type        = string
  description = "Plan for your load balancer service."
  default     = "production-small"
}

variable "upcloud_dns_servers_ipv4" {
  type        = list(string)
  description = "List of UpCloud DNS servers (IPv4). This is required to properly set up firewall rules. In most cases you should just leave the default value."
  default     = ["94.237.127.9", "94.237.40.9"]
}

variable "upcloud_dns_servers_ipv6" {
  type        = list(string)
  description = "List of UpCloud DNS servers (IPv6). This is required to properly set up firewall rules. In most cases you should just leave the default value."
  default     = ["2a04:3540:53::1", "2a04:3544:53::1"]
}
