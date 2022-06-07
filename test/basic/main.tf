terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 2.4"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "upcloud" {}
provider "cloudflare" {}

variable "subdomain_name" {
  type        = string
  description = "Subdomain name that will be used for the test. Should be a unique(ish) value to prevent collisions when running this test in multiple places"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "ID of the cloudflare zone that will be used to setup subdomain with CNAME record pointing at load balancer URL"
}

variable "servers_ssh_keys" {
  type        = list(string)
  description = "SSH keys for your servers"
}

variable "own_public_ip" {
  type = string
  description = "Public IP address (v4) of the machine on which the test is run on. This is needed to setup firewall rules correctly"
}

data "cloudflare_zone" "domain" {
  zone_id = var.cloudflare_zone_id
}

locals {
  full_domain_name = "${var.subdomain_name}.${data.cloudflare_zone.domain.name}"
}

module "app" {
  source = "../../"

  app_name                 = "super_app"
  zone                     = "pl-waw1"
  private_network_cidr     = "10.0.51.0/24"
  servers_port             = 80
  domains                  = [local.full_domain_name]
  database_type            = "MySQL"
  servers_ssh_keys         = var.servers_ssh_keys
  servers_firewall_enabled = true
  servers_allowed_remote_ips = [var.own_public_ip]
}

resource "cloudflare_record" "lb_dns_record" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.subdomain_name
  value   = module.app.app_url
  type    = "CNAME"
  ttl     = 1
}

output "servers_public_ips" {
  value = module.app.web_servers_public_ips
}

output "url" {
  value = local.full_domain_name
}

output "db_host" {
  value = module.app.database_host
}

output "db_port" {
  value = module.app.database_port
}

output "primary_db" {
  value = module.app.databse_primary_db
}

output "db_username" {
  value = module.app.database_service_username
}

output "db_password" {
  value     = module.app.database_service_password
  sensitive = true
}
