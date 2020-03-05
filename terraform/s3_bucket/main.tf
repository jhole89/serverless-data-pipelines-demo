resource "aws_s3_bucket" "encrypted_bucket" {
  acl = "private"
  force_destroy = "true"
  bucket = "${var.domain}.${var.bucket_name}"
  tags = var.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_glue_catalog_database" "database" {
  name = "${var.database_name}_${var.bucket_name}"
}

resource "aws_glue_crawler" "s3_crawler" {
  database_name = aws_glue_catalog_database.database.name
  name = "${var.bucket_name}Crawler"
  role = var.glue_role_arn

  s3_target {
    path = "s3://${aws_s3_bucket.encrypted_bucket.bucket}"
    exclusions = concat(["**_SUCCESS", "**crc"])
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }
}
