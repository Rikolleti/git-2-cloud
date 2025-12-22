variable "yc_token" {
  description = "Yandex Cloud IAM token"
  type        = string
}

variable "cloud_id" {
  description = "Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Folder ID"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "metadata" {
  type        = map(string)
  description = "Instance metadata (ssh-keys, serial-port-enable, etc.)"
}
