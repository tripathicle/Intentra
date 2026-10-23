
# RESOURCE GROUP MODULE



module "resource_group" {
  source = "git::https://github.com/tripathicle/azurerm-resource-group.git?ref=v1.0.0"

  resource_groups = var.resource_groups
  tags            = var.tags
}


# STORAGE ACCOUNT MODULE


module "storage_account" {
  source = "git::https://github.com/tripathicle/azurerm-storage-account.git?ref=v1.0.0"

  storage_accounts   = var.storage_accounts
  storage_containers = var.storage_containers
  resource_groups    = module.resource_group.resource_groups
  tags               = var.tags
}



# VNET MODULE


module "vnet" {
  source = "git::https://github.com/tripathicle/azurerm-virtual-network.git?ref=v1.0.0"

  vnets           = var.vnets
  resource_groups = module.resource_group.resource_groups
  tags            = var.tags
}



# SUBNET MODULE


module "subnet" {
  source = "git::https://github.com/tripathicle/azurerm-subnet.git?ref=v1.0.0"

  subnets = var.subnets
  vnets   = module.vnet.vnets
}



# VNET PEERING MODULE

module "vnet_peering" {
  source = "git::https://github.com/tripathicle/azurerm-virtual-network-peering.git?ref=v1.0.0"

  vnet_peerings = var.vnet_peerings
  vnets         = module.vnet.vnets
}



# PUBLIC IP MODULE


module "public_ip" {
  source = "git::https://github.com/tripathicle/azurerm-public-ip.git?ref=v1.0.0"

  public_ips      = var.public_ips
  resource_groups = module.resource_group.resource_groups
  tags            = var.tags
}



# NSG MODULE


module "nsg" {
  source = "git::https://github.com/tripathicle/azurerm-network-security-group.git?ref=v1.0.0"

  network_security_groups = var.network_security_groups
  resource_groups         = module.resource_group.resource_groups
  tags                    = var.tags
}



# NSG ASSOCIATION MODULE


module "nsg_association" {
  source = "git::https://github.com/tripathicle/azurerm-subnet-nsg-association.git?ref=v1.0.0"

  nsg_associations        = var.nsg_associations
  network_security_groups = module.nsg.network_security_groups
  subnets                 = module.subnet.subnets
}



# INTERNAL LOAD BALANCER MODULE


module "lb" {
  source = "git::https://github.com/tripathicle/azurerm-load-balancer.git?ref=v1.0.0"

  load_balancers = var.load_balancers

  resource_groups = module.resource_group.resource_groups
  subnets         = module.subnet.subnets

  tags = var.tags
}


# NETWORK INTERFACE MODULE


module "nic" {
  source = "git::https://github.com/tripathicle/azurerm-network-interface.git?ref=v1.0.0"

  network_interfaces = var.network_interfaces

  resource_groups = module.resource_group.resource_groups
  subnets         = module.subnet.subnets

  backend_address_pools = module.lb.backend_address_pools

  tags = var.tags
}



# VIRTUAL MACHINES



module "vm" {
  source = "git::https://github.com/tripathicle/azurerm-virtual-machine.git?ref=v1.0.0"

  virtual_machines = {
    for key, vm in var.virtual_machines :
    key => merge(
      vm,
      {
        admin_ssh_key = (
          vm.os_type == "Linux"
          ? var.admin_ssh_public_key
          : try(vm.admin_ssh_key, null)
        )
      }
    )
  }

  resource_groups    = module.resource_group.resource_groups
  network_interfaces = module.nic.network_interfaces

  tags = var.tags
}






# APPLICATION GATEWAY / WAF MODULE


module "gateway" {
  source = "git::https://github.com/tripathicle/azurerm-application-gateway.git?ref=v1.0.0"

  application_gateways = var.application_gateways
  resource_groups      = module.resource_group.resource_groups
  subnets              = module.subnet.subnets
  public_ips           = module.public_ip.public_ips
  tags                 = var.tags
}



# AZURE BASTION MODULE


module "bastion" {
  source = "git::https://github.com/tripathicle/azurerm-bastion-host.git?ref=v1.0.0"

  bastions = var.bastions

  resource_groups = module.resource_group.resource_groups
  subnets         = module.subnet.subnets
  public_ips      = module.public_ip.public_ips

  tags = var.tags
}


# AZURE SQL


module "sql" {
  source = "git::https://github.com/tripathicle/azurerm-mssql-server.git?ref=v1.0.3"

  sql_servers = var.sql_servers

  resource_groups = module.resource_group.resource_groups

  administrator_password = var.sql_admin_password

  vulnerability_assessment_storage = local.vulnerability_assessment_storage

  tags = var.tags
}



# POSTGRESQL FLEXIBLE SERVER


module "postgresql" {
  source = "git::https://github.com/tripathicle/azurerm-postgresql-flexible-server.git?ref=v1.0.0"

  postgresql_servers = var.postgresql_servers

  resource_groups = module.resource_group.resource_groups

  administrator_password = var.postgresql_admin_password

  tags = var.tags
}


# 
# PRIVATE ACCESS
#
# Creates:
#   - Private DNS Zones
#   - Private DNS Zone -> VNet Links
#   - Private Endpoints
#

module "private_access" {
  source = "git::https://github.com/tripathicle/azurerm-private-endpoint-and-dns.git?ref=v1.0.0"

  private_endpoints = local.private_endpoints

  private_dns_zones = var.private_dns_zones

  private_dns_zone_vnet_links = (
    var.private_dns_zone_vnet_links
  )

  resource_groups = module.resource_group.resource_groups

  subnets = module.subnet.subnets

  vnets = module.vnet.vnets

  tags = var.tags
}


# 
# KEY VAULT
#
# Creates:
#   - Azure Key Vault
#   - RBAC authorization
#   - Soft delete
#   - Purge protection
#
# No secrets are created at this stage.
#

module "key_vault" {
  source = "git::https://github.com/tripathicle/azurerm-key-vault.git?ref=v1.0.0"

  key_vaults = var.key_vaults

  resource_groups = module.resource_group.resource_groups

  tags = var.tags
}


#
# MONITORING
#
# Creates:
#   - Log Analytics Workspace
#   - Workspace-based Application Insights
#
# Diagnostic settings and alerts will be added separately.
# 



module "monitoring" {
  source = "git::https://github.com/tripathicle/azurerm-monitoring.git?ref=v1.0.0"

  monitoring = var.monitoring

  resource_groups = module.resource_group.resource_groups

  tags = var.tags
}

