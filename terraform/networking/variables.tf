variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "windows_vms" {
  description = "Map of Windows VM names to deploy"
  type        = map(string)
}

variable "linux_vms" {
  description = "Map of Linux VM names to deploy"
  type        = map(string)
}
