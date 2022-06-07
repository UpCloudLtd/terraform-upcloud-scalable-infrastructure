terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 2.4"
    }
  }
}

resource "upcloud_network" "private_network" {
  name = "${var.app_name}_private_network"
  zone = var.zone
  ip_network {
    dhcp    = true
    family  = "IPv4"
    address = var.private_network_cidr
  }
}

resource "upcloud_managed_database_postgresql" "db" {
  count = var.database_type == "PostgreSQL" ? 1 : 0
  name  = "${replace(var.app_name, "/[^a-zA-Z0-9]/", "")}db"
  plan  = var.database_plan
  title = "${var.app_name}_db"
  zone  = var.zone

  properties {
    public_access = false
  }
}

resource "upcloud_managed_database_mysql" "db" {
  count = var.database_type == "MySQL" ? 1 : 0
  name  = "${replace(var.app_name, "/[^a-zA-Z0-9]/", "")}db"
  plan  = var.database_plan
  title = "${var.app_name}_db"
  zone  = var.zone

  properties {
    public_access = false
  }
}

resource "upcloud_server" "web_servers" {
  count    = var.servers_count
  hostname = "${replace(var.app_name, "/[^a-zA-Z0-9]/", "")}${count.index}"
  title    = "${var.app_name}_server_${count.index}"
  zone     = var.zone
  plan     = var.servers_plan
  firewall = var.servers_firewall_enabled

  template {
    storage = var.servers_template
    size    = var.servers_template_storage_size
  }

  login {
    keys = var.servers_ssh_keys
  }

  network_interface {
    type = "utility"
  }

  network_interface {
    type              = "public"
    ip_address_family = "IPv4"
  }

  network_interface {
    type              = "public"
    ip_address_family = "IPv6"
  }

  network_interface {
    type    = "private"
    network = upcloud_network.private_network.id
  }
}

resource "upcloud_firewall_rules" "web_server_firewalls" {
  for_each  = { for v in upcloud_server.web_servers : v.title => v.id }
  server_id = each.value

  dynamic "firewall_rule" {
    for_each = var.upcloud_dns_servers_ipv4

    content {
      action                 = "accept"
      comment                = "Allow UpCloud DNS server (IPv4)"
      destination_port_end   = ""
      destination_port_start = ""
      direction              = "in"
      family                 = "IPv4"
      protocol               = "tcp"
      source_address_end     = firewall_rule.value
      source_address_start   = firewall_rule.value
      source_port_end        = "53"
      source_port_start      = "53"
    }
  }

  dynamic "firewall_rule" {
    for_each = var.upcloud_dns_servers_ipv4

    content {
      action                 = "accept"
      comment                = "Allow UpCloud DNS server (IPv4)"
      destination_port_end   = ""
      destination_port_start = ""
      direction              = "in"
      family                 = "IPv4"
      protocol               = "udp"
      source_address_end     = firewall_rule.value
      source_address_start   = firewall_rule.value
      source_port_end        = "53"
      source_port_start      = "53"
    }
  }

  dynamic "firewall_rule" {
    for_each = var.upcloud_dns_servers_ipv6

    content {
      action                 = "accept"
      comment                = "Allow UpCloud DNS server (IPv6)"
      destination_port_end   = ""
      destination_port_start = ""
      direction              = "in"
      family                 = "IPv6"
      protocol               = "tcp"
      source_address_end     = firewall_rule.value
      source_address_start   = firewall_rule.value
      source_port_end        = "53"
      source_port_start      = "53"
    }
  }

  dynamic "firewall_rule" {
    for_each = var.upcloud_dns_servers_ipv6

    content {
      action                 = "accept"
      comment                = "Allow UpCloud DNS server (IPv6)"
      destination_port_end   = ""
      destination_port_start = ""
      direction              = "in"
      family                 = "IPv6"
      protocol               = "udp"
      source_address_end     = firewall_rule.value
      source_address_start   = firewall_rule.value
      source_port_end        = "53"
      source_port_start      = "53"
    }
  }

  dynamic "firewall_rule" {
    for_each = var.servers_allowed_remote_ips

    content {
      action                 = "accept"
      comment                = "Allow SSH from this network"
      destination_port_end   = "22"
      destination_port_start = "22"
      direction              = "in"
      family                 = "IPv4"
      protocol               = "tcp"
      source_address_end     = firewall_rule.value
      source_address_start   = firewall_rule.value
    }
  }

  firewall_rule {
    action                 = "drop"
    comment                = "Default drop incoming IPv4"
    destination_port_end   = ""
    destination_port_start = ""
    direction              = "in"
    family                 = "IPv4"
    protocol               = ""
    source_address_end     = ""
    source_address_start   = ""
  }

  firewall_rule {
    action                 = "drop"
    comment                = "Default drop incoming IPv6"
    destination_port_end   = ""
    destination_port_start = ""
    direction              = "in"
    family                 = "IPv6"
    protocol               = ""
    source_address_end     = ""
    source_address_start   = ""
  }
}

module "load_balancer" {
  source  = "UpCloudLtd/basic-loadbalancer/upcloud"
  version = "1.0.0"

  network             = upcloud_network.private_network.id
  backend_servers     = [for v in upcloud_server.web_servers : v.network_interface.3.ip_address]
  backend_server_port = var.servers_port
  max_server_sessions = var.max_server_sessions
  name                = "${var.app_name}_load_balancer"
  domains             = var.domains
  plan                = var.load_balancer_plan
  zone                = var.zone
}
