resource "azurerm_windows_virtual_machine" "student_win_server" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = "B2s"
  admin_username        = "ita"
  admin_password        = "820BruceStreet"
  network_interface_ids = [var.nic_id]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  computer_name      = var.vm_name
  provision_vm_agent = true
}
