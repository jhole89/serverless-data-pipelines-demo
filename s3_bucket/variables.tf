variable "domain" {}

variable "bucket_name" {}

variable "database_name" {}

variable "crawler_path" {
  default = ""
}

variable "kms_key_id" {}

variable "tags" {}

variable "glue_role_arn" {}
