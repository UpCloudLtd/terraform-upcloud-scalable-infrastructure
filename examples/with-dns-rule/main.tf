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

data "cloudflare_zone" "domain" {
  zone_id = "your-cloudflare-zone-id"
}

locals {
  subdomain = "app"
  full_domain_name = "${local.subdomain}.${data.cloudflare_zone.domain.name}"
}

module "app" {
  source = "UpCloudLtd/highly-available-app/upcloud"

  app_name                 = "super_app"
  zone                     = "pl-waw1"
  private_network_cidr     = "10.0.51.0/24"
  servers_port             = 80
  domains                  = [local.full_domain_name]
  database_type            = "MySQL"
  servers_ssh_keys         = ["your-public-ssh-key"]
  servers_firewall_enabled = true
  servers_allowed_remote_ips = ["123.123.123.123"]
}

resource "cloudflare_record" "lb_dns_record" {
  zone_id = data.cloudflare_zone.domain.id
  name    = local.subdomain
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
