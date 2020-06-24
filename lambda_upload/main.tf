locals {
  lowercase_lambda = lower(var.lambda_name)
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${var.lambda_repo}/${local.lowercase_lambda}"
  output_path = "${var.lambda_repo}/${local.lowercase_lambda}.zip"
}

resource "aws_s3_bucket_object" "lambda_zip" {
  bucket = var.bucket_name
  key    = "${var.upload_dir}/${local.lowercase_lambda}.zip"
  source = data.archive_file.lambda.output_path
  etag   = filemd5(data.archive_file.lambda.output_path)
  tags   = var.tags
}
