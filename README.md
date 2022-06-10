# UpCloud scalable infrastructure

Terraform module which creates an easy to scale web app with a managed database, multiple web servers and a load balancer in front of them.

## Usage
```hcl
module "app" {
  source = "UpCloudLtd/scalable-infrastructure/upcloud"

  app_name                   = "super_app"
  zone                       = "pl-waw1"
  private_network_cidr       = "10.0.51.0/24"
  servers_port               = 80
  domains                    = ["my.domain.net"]
  servers_ssh_keys           = ["your-public-ssh-key"]
  servers_firewall_enabled   = true
  servers_allowed_remote_ips = ["95.123.98.33"]
}
```
