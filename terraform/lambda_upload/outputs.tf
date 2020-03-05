output "lambda_zip_key" {
  value = aws_s3_bucket_object.lambda_zip.key
}

output "lambda_zip_version_id" {
  value = aws_s3_bucket_object.lambda_zip.version_id
}
