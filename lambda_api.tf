module "api_sourcing_upload" {
  source = "./lambda_upload"

  lambda_name = var.api_lambda_name
  lambda_repo = var.lambda_scripts_repo
  bucket_name = module.code_staging.s3_bucket_name
  upload_dir = "lambdas/sourcing"
  tags = var.tags
}

module "api_lambda" {
  source = "./python_lambda"

  lambda_name = var.api_lambda_name
  lambda_zip_hash = module.api_sourcing_upload.lambda_zip_hash
  s3_bucket_name = module.code_staging.s3_bucket_name
  s3_key = module.api_sourcing_upload.lambda_zip_key
  s3_object_version = module.api_sourcing_upload.lambda_zip_version_id
  lambda_execution_role_arn = aws_iam_role.lambda_execution_role.arn
  tags = var.tags
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "s3-lambda-execution-role"
  tags = var.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda_get_staging" {
  name = "lambda-execution-get-staging-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_staging.json
  role = aws_iam_role.lambda_execution_role.id
}

resource "aws_iam_role_policy" "lambda_put_landing" {
  name = "lambda-execution-put-landing-policy"
  policy = data.aws_iam_policy_document.allow_s3_put_landing.json
  role = aws_iam_role.lambda_execution_role.id
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "lambda-execution-logs-policy"
  role = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.allow_logging.json
}

resource "aws_iam_role_policy" "lambda_networking" {
  name = "lambda-execution-network-interface-policy"
  role = aws_iam_role.lambda_execution_role.id
  policy =  data.aws_iam_policy_document.allow_network_interface_creation.json
}

resource "aws_iam_role_policy" "lambda_kms_access" {
  name = "lambda-execution-kms-access-policy"
  role = aws_iam_role.lambda_execution_role.id
  policy =  data.aws_iam_policy_document.allow_kms_access.json
}