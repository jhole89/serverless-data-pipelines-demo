module "landing_zone" {
  source = "./s3_bucket"

  bucket_name   = "landing"
  database_name = var.project_name
  domain        = var.domain
  crawler_path  = var.api_table_name
  glue_role_arn = aws_iam_role.glue_crawler_execution_role.arn
  kms_key_id    = aws_kms_key.s3_encryption_key.arn
  tags          = var.tags
}

module "trusted_zone" {
  source = "./s3_bucket"

  bucket_name   = "trusted"
  database_name = var.project_name
  domain        = var.domain
  crawler_path  = var.api_table_name
  glue_role_arn = aws_iam_role.glue_crawler_execution_role.arn
  kms_key_id    = aws_kms_key.s3_encryption_key.arn
  tags          = var.tags
}

module "analytics_zone" {
  source = "./s3_bucket"

  bucket_name   = "analytics"
  database_name = var.project_name
  domain        = var.domain
  crawler_path  = var.api_table_name
  glue_role_arn = aws_iam_role.glue_crawler_execution_role.arn
  kms_key_id    = aws_kms_key.s3_encryption_key.arn
  tags          = var.tags
}

module "athena_queries" {
  source = "./s3_bucket"

  bucket_name   = "queries"
  database_name = var.project_name
  domain        = var.domain
  glue_role_arn = aws_iam_role.glue_crawler_execution_role.arn
  kms_key_id    = aws_kms_key.s3_encryption_key.arn
  tags          = var.tags
}

module "code_staging" {
  source = "./s3_bucket"

  bucket_name   = "staging"
  database_name = var.project_name
  domain        = var.domain
  glue_role_arn = aws_iam_role.glue_crawler_execution_role.arn
  kms_key_id    = aws_kms_key.s3_encryption_key.arn
  tags          = var.tags
}

resource "aws_iam_role" "glue_crawler_execution_role" {
  name = "glue-crawler-execution-role"

  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_crawler_glue_service" {
  role       = aws_iam_role.glue_crawler_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_crawler_get_analytics" {
  name   = "glue-crawler-get-analytics-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_analytics.json
  role   = aws_iam_role.glue_crawler_execution_role.id
}

resource "aws_iam_role_policy" "glue_crawler_get_landing" {
  name   = "glue-crawler-get-landing-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_landing.json
  role   = aws_iam_role.glue_crawler_execution_role.id
}

resource "aws_iam_role_policy" "glue_crawler_get_trusted" {
  name   = "glue-crawler-get-trusted-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_trusted.json
  role   = aws_iam_role.glue_crawler_execution_role.id
}

resource "aws_iam_role_policy" "glue_crawler_kms_access" {
  name   = "glue-crawler-kms-access-policy"
  policy = data.aws_iam_policy_document.allow_kms_access.json
  role   = aws_iam_role.glue_crawler_execution_role.id
}
