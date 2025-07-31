provider "azurerm" {
  features {}
  subscription_id = "10150ec8-4a52-423c-a87b-5ccbb4a27cf4"
}

resource "azurerm_resource_group" "lab_rg" {
  name     = "server-labs"
  location = "East US 2"
}

variable "vm_instances" {
  description = "Map of VM names to deploy"
  type        = map(string)
  default = {
    "vm1" = "student-vm-01"
    "vm2" = "student-vm-02"
  }
}

module "networking" {
  source              = "./networking"
  name_prefix         = "student"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
}

module "windows_server" {
  source              = "./windows_server"
  vm_name             = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  nic_id              = module.networking.nic_id
}

module "linux_server" {
  source              = "./linux_server"
  vm_name             = "student-linux-server-1"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
  subnet_id           = module.windows_server.subnet_id
  admin_username      = "ita"
  admin_password      = "820ITAcademy"
}
