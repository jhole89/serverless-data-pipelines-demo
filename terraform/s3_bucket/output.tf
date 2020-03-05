output "s3_bucket_name" {
  value = aws_s3_bucket.encrypted_bucket.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.encrypted_bucket.arn
}

output "crawler_name" {
  value = aws_glue_crawler.s3_crawler.name
}

output "glue_catalog_database_name" {
  value = aws_glue_catalog_database.database.name
}