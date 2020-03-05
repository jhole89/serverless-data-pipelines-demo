resource "aws_kms_key" "s3_encryption_key" {
  enable_key_rotation = "true"
  tags = var.tags
}

resource "aws_kms_alias" "s3_enrypted_key_alias" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.s3_encryption_key.key_id
}
