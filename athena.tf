resource "aws_athena_workgroup" "DataConsumers" {

  name = var.athena_workgroup_name
  tags = var.tags

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.athena_queries.s3_bucket_name}"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.s3_encryption_key.arn
      }
    }
  }
}
