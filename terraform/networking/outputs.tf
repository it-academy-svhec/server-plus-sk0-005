output "windows_nic_ids" {
  value = { for k, v in azurerm_network_interface.windows_nic : k => v.id }
}

output "linux_nic_ids" {
  value = { for k, v in azurerm_network_interface.linux_nic : k => v.id }
}
