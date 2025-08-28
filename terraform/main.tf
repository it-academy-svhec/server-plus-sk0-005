provider "azurerm" {
  features {}
  subscription_id = "10150ec8-4a52-423c-a87b-5ccbb4a27cf4"
}

resource "azurerm_resource_group" "lab_rg" {
  name     = "server-labs"
  location = "East US 2"
}

variable "windows_vms" {
  description = "Map of Windows VM names to deploy"
  type        = map(string)
  default = {
    "vm1" = "win-srv-1"
    "vm2" = "win-srv-2"
  }
}

variable "linux_vms" {
  description = "Map of Linux VM names to deploy"
  type        = map(string)
  default = {
    "vm1" = "linux-srv-1"
    "vm2" = "linux-srv-2"
  }
}

module "networking" {
  source              = "./networking"
  name_prefix         = "student"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
  windows_vms         = var.windows_vms
  linux_vms           = var.linux_vms
}

module "infra" {
  source              = "./infra"
  name_prefix         = "student"
  resource_group_name = "server-infra"
  location            = "East US 2"
}

module "windows_server" {
  for_each            = var.windows_vms
  source              = "./windows_server"
  vm_name             = each.value
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  nic_id              = module.networking.windows_nic_ids[each.key]
  admin_username      = "ita"
  admin_password      = "820BruceStreet"
}

module "linux_server" {
  for_each            = var.linux_vms
  source              = "./linux_server"
  vm_name             = each.value
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
  nic_id              = module.networking.linux_nic_ids[each.key]
  admin_username      = "ita"
  admin_password      = "820BruceStreet"
}
