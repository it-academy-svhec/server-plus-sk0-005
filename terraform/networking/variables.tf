variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

output "nic_ids" {
  value = {
    for nic_key, nic in azurerm_network_interface.student_win_server_nic :
    nic_key => nic.id
  }
}
