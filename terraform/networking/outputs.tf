output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

output "network_security_group_id" {
  value = azurerm_network_security_group.student_server_nsg.id
}

output "public_ip_id" {
  value = azurerm_public_ip.student_win_server_ip.id
}

output "nic_id" {
  value = azurerm_network_interface.student_win_server_nic.id
}
