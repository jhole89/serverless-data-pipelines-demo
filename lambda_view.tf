module "view_upload" {
  source = "./lambda_upload"

  lambda_name = var.athena_query_trigger_name
  lambda_repo = var.lambda_scripts_repo
  bucket_name = module.code_staging.s3_bucket_name
  upload_dir  = "lambdas/triggers"
  tags        = var.tags
}

module "view_lambda" {
  source = "./python_lambda"

  lambda_name               = var.athena_query_trigger_name
  lambda_zip_hash           = module.view_upload.lambda_zip_hash
  s3_bucket_name            = module.code_staging.s3_bucket_name
  s3_key                    = module.view_upload.lambda_zip_key
  s3_object_version         = module.view_upload.lambda_zip_version_id
  lambda_execution_role_arn = aws_iam_role.view_execution_role.arn
  tags                      = var.tags
}

resource "aws_iam_role" "view_execution_role" {
  name = "view-lambda-execution-role"
  tags = var.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "view_lambda_networking" {
  name   = "athena-execution-network-interface-policy"
  role   = aws_iam_role.view_execution_role.id
  policy = data.aws_iam_policy_document.allow_network_interface_creation.json
}

resource "aws_iam_role_policy" "view_lambda_logs" {
  name   = "athena-execution-view-lambda-logs-policy"
  role   = aws_iam_role.view_execution_role.id
  policy = data.aws_iam_policy_document.allow_logging.json
}

resource "aws_iam_role_policy" "view_kms_access" {
  name   = "athena-execution-kms-access-policy"
  role   = aws_iam_role.view_execution_role.id
  policy = data.aws_iam_policy_document.allow_kms_access.json
}

resource "aws_iam_role_policy" "view_lambda_athena_access" {
  name   = "athena-execution-query-policy"
  role   = aws_iam_role.view_execution_role.id
  policy = data.aws_iam_policy_document.allow_athena_query_execution.json
}

resource "aws_iam_role_policy" "view_lambda_s3_access" {
  name   = "athena-execution-results-access-policy"
  role   = aws_iam_role.view_execution_role.id
  policy = data.aws_iam_policy_document.allow_s3_athena_results.json
}

resource "aws_iam_role_policy" "view_lambda_glue_access" {
  name   = "athena-execution-catalog-access-policy"
  role   = aws_iam_role.view_execution_role.id
  policy = data.aws_iam_policy_document.allow_glue_table_creation.json
}
