variable "yandex_cloud_id" {
  description = "Yandex Cloud Cloud ID"
  type        = string
  sensitive   = true
}

variable "yandex_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "C:/Users/Nikit/.ssh/id_rsa.pub"
}