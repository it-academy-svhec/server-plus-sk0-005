variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "nic_id" {
  type = string
}

