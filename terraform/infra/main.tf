variable "name_prefix" {
  type = "linux-infra-1"
}

# Public IP
resource "azurerm_public_ip" "linux_vm_pip" {
  name                = "${var.name_prefix}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic" # or "Static" if you want a fixed IP
  sku                 = "Basic"
}

# Network Interface
resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "${var.name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_vm_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                            = var.name_prefix
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = "Standard_B1s"
  admin_username                  = "ita"
  admin_password                  = "820ITAcademy"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.linux_vm_nic.id
  ]

  os_disk {
    name                 = "linux-infra-1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "24_04-lts"
    version   = "latest"
  }

  computer_name      = "linux-infra-1"
  provision_vm_agent = true
}
