variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type = number
  default = 517142019302
}

variable "domain" {
  default = "manta-innovations"
}

variable "landing_bucket_name" {
  default = "landing"
}

variable "trusted_bucket_name" {
  default = "trusted"
}

variable "analytics_bucket_name" {
  default = "analytics"
}

variable "code_staging_bucket_name" {
  default = "staging"
}

variable "athena_query_bucket_name" {
  default = "queries"
}

variable "kms_key_alias" {
  default = "s3-encryption-key"
}

variable "database_name" {
  default = "demo"
}

variable "api_lambda_name" {
  default = "Api_Sourcing"
}

variable "glue_crawler_trigger_name" {
  default = "glue_crawler_initiation"
}

variable "athena_query_trigger_name" {
  default = "athena_query_execution"
}

variable "athena_workgroup_name" {
  default = "DataConsumers"
}

variable "view_list" {
  default = "CVAS.sql"
}

variable "glue_scripts_repo" {
  default = "./glue_scripts"
}

variable "lambda_scripts_repo" {
  default = "./lambdas"
}

variable "source_path" {
  default = ""
}

variable "output_path" {
  default = ""
}

variable "timeout_seconds" {
  type = number
  default = 900
}

variable "log_retention_days" {
  type = number
  default = 14
}

variable "glue_max_capacity" {
  type = number
  default = 2
}

variable "cron_schedule" {
  default = "cron(0 10 * * ? *)"
}

variable "tags" {
  type = map(string)
  default = {
    terraform = "true"
    demo = "Vancouver AWS User Group Meetup 03/2020"
  }
}
