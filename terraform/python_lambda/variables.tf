variable "lambda_name" {}

variable "lambda_execution_role_arn" {}

variable "s3_bucket_name" {}

variable "s3_key" {}

variable "s3_object_version" {}

variable "tags" {}

variable "timeout_seconds" {
  type = number
  default = 900
}

variable "lambda_memory_size" {
  type = number
  default = 128
}

variable "log_retention_days" {
  type = number
  default = 14
}

variable "env_vars" {
  type = map(string)
  default = {}
}
