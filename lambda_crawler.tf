module "crawler_upload" {
  source = "./lambda_upload"

  lambda_name = var.glue_crawler_trigger_name
  lambda_repo = var.lambda_scripts_repo
  bucket_name = module.code_staging.s3_bucket_name
  upload_dir = "lambdas/triggers"
  tags = var.tags
}

module "crawler_lambda" {
  source = "./python_lambda"

  lambda_name = var.glue_crawler_trigger_name
  s3_bucket_name = module.code_staging.s3_bucket_name
  s3_key = module.crawler_upload.lambda_zip_key
  s3_object_version = module.crawler_upload.lambda_zip_version_id
  lambda_execution_role_arn = aws_iam_role.lambda_crawler_trigger_role.arn
  tags = var.tags
}

resource "aws_iam_role" "lambda_crawler_trigger_role" {
  name = "lambda-crawler-trigger-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_crawler_glue_crawler_execution" {
  name = "lambda-crawler-invoke-crawler-policy"
  role = aws_iam_role.lambda_crawler_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_glue_crawler_execution.json
}

resource "aws_iam_role_policy" "lambda_crawler_logs" {
  name = "lambda-crawler-logs-policy"
  role = aws_iam_role.lambda_crawler_trigger_role.id
  policy = data.aws_iam_policy_document.allow_logging.json
}
