variable "yc_token" {
  type        = string
  description = "IAM токен Yandex Cloud"
  sensitive   = true
}

variable "yc_cloud_id" {
  type        = string
  description = "ID облака"
}

variable "yc_folder_id" {
  type        = string
  description = "ID каталога"
}

variable "ssh_key_path" {
  type        = string
  description = "Путь к публичному SSH-ключу"
  default     = "~/.ssh/yc_key.pub"
}
