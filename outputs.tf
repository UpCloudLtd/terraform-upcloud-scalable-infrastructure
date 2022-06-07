locals {
  db = var.database_type == "PostgreSQL" ? upcloud_managed_database_postgresql.db.0 : upcloud_managed_database_mysql.db.0
}

output "app_url" {
  value       = module.load_balancer.dns_name
  description = "URL at which the load balancer serves the app. You should add a CNAME record for your domain(s) that point to this address."
}

output "web_servers_public_ips" {
  value       = [for v in upcloud_server.web_servers : v.network_interface.1.ip_address]
  description = "Public IPs for all webservers."
}

output "web_servers_ids" {
  value       = [for v in upcloud_server.web_servers : v.id]
  description = "List of web servers IDs. Can be used to reference in other resources."
}

output "database_id" {
  value       = local.db.id
  description = "ID of the used database service. Can be used to create additional users and logical databases."
}

output "database_host" {
  value       = local.db.service_host
  description = "Hostname of your database service."
}

output "database_port" {
  value       = local.db.service_port
  description = "Port at which your database service listens for connections."
}

output "databse_primary_db" {
  value       = local.db.primary_database
  description = "Primary logical database of your database service."
}

output "database_service_username" {
  value       = local.db.service_username
  description = "Primary username of your database service."
}

output "database_service_password" {
  value       = local.db.service_password
  description = "Primary password of your database service."
  sensitive   = true
}

output "database_service_uri" {
  value     = local.db.service_uri
  sensitive = true
}

output "loadbalancer_id" {
  value       = module.load_balancer.id
  description = "ID of the load balancer service. Can be used to create additional backends, frontends and resolvers."
}

output "loadbalancer_frontend_id" {
  value       = module.load_balancer.frontend_id
  description = "ID of the load balancer frontend. Can be used to attach additional frontend rules."
}

output "loadbalancer_backend_id" {
  value       = module.load_balancer.backend_id
  description = "ID of the load balancer backend."
}


