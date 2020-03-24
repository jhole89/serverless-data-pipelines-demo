module "comprehend_upload" {
  source = "./lambda_upload"

  lambda_name = var.comprehend_trigger_name
  lambda_repo = var.lambda_scripts_repo
  bucket_name = module.code_staging.s3_bucket_name
  upload_dir = "lambdas/triggers"
  tags = var.tags
}

module "comprehend_lambda" {
  source = "./python_lambda"

  lambda_name = var.comprehend_trigger_name
  lambda_zip_hash = module.comprehend_upload.lambda_zip_hash
  s3_bucket_name = module.code_staging.s3_bucket_name
  s3_key = module.comprehend_upload.lambda_zip_key
  s3_object_version = module.comprehend_upload.lambda_zip_version_id
  lambda_execution_role_arn = aws_iam_role.lambda_comprehend_trigger_role.arn
  tags = var.tags
}

resource "aws_iam_role" "lambda_comprehend_trigger_role" {
  name = "lambda-comprehend-trigger-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags = var.tags
}


resource "aws_iam_role_policy" "comprehend_lambda_networking" {
  name = "lambda-comprehend-network-interface-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_network_interface_creation.json
}

resource "aws_iam_role_policy" "comprehend_lambda_logs" {
  name = "lambda-comprehend-view-lambda-logs-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy = data.aws_iam_policy_document.allow_logging.json
}

resource "aws_iam_role_policy" "comprehend_kms_access" {
  name = "lambda-comprehend-kms-access-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_kms_access.json
}

resource "aws_iam_role_policy" "comprehend_lambda_athena_access" {
  name = "lambda-comprehend-query-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_athena_query_execution.json
}

resource "aws_iam_role_policy" "comprehend_lambda_glue_access" {
  name = "lambda-comprehend-catalog-access-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_glue_table_creation.json
}

resource "aws_iam_role_policy" "comprehend_lambda_results_access" {
  name = "lambda-comprehend-results-access-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_s3_athena_results.json
}

resource "aws_iam_role_policy" "comprehend_lambda_trusted_access" {
  name = "lambda-comprehend-trusted-access-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_s3_get_trusted.json
}

resource "aws_iam_role_policy" "comprehend_lambda_detect_entities" {
  name = "lambda-comprehend-detect-entities-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy = data.aws_iam_policy_document.allow_comprehend_detection.json
}

resource "aws_iam_role_policy" "comprehend_lambda_put_analytics" {
  name = "lambda-comprehend-put-analytics-policy"
  role = aws_iam_role.lambda_comprehend_trigger_role.id
  policy = data.aws_iam_policy_document.allow_s3_put_analytics.json
}
