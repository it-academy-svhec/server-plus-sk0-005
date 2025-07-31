variable "vm_name" {
  description = "Name of the Linux VM"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to attach NIC to"
  type        = string
}

variable "admin_username" {
  description = "Admin username for login"
  type        = string
}

variable "admin_password" {
  description = "Admin password for login"
  type        = string
  sensitive   = true
}
