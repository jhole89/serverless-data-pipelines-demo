data "archive_file" "lambda" {
  type = "zip"
  source_dir = "./lambdas/${var.lambda_name}"
  output_path = "./lambdas/${var.lambda_name}.zip"
}

resource "aws_s3_bucket_object" "lambda_zip" {
  bucket = var.bucket_name
  key = "${var.upload_dir}/${var.lambda_name}.zip"
  source = data.archive_file.lambda.output_path
  etag = filemd5(data.archive_file.lambda.output_path)
  tags = var.tags
}
