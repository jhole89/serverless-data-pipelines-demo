variable "aws_region" {
  description = "AWS region to launch servers."
}

variable "account_id" {
  description = "AWS Account ID"
  type = number
}

variable "domain" {
  default = "manta-innovations"
}

variable "kms_key_alias" {
  default = "s3-encryption-key"
}

variable "project_name" {
  default = "demo"
}

variable "api_lambda_name" {
  default = "Api_Sourcing"
}

variable "api_key" {}

variable "api_url" {
  default = "api.bestbuy.com/v1/products(new=true)?show=sku,productId,name,source,type,active,lowPriceGuarantee,activeUpdateDate,regularPrice,salePrice&format=json"
}

variable "api_page_size" {
  default = 100
}

variable "api_data_key" {
  default = "products"
}

variable "api_table_name" {
  default = "products"
}

variable "glue_crawler_trigger_name" {
  default = "glue_crawler_initiation"
}

variable "athena_query_trigger_name" {
  default = "athena_query_execution"
}

variable "comprehend_trigger_name" {
  default = "comprehend_analysis"
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
    demo = "Vancouver AWS User Group Meetup"
  }
}
