locals {
  glue_script_name = "ApiScript"
  glue_jar_name = "${var.domain}-${var.project_name}-shared.jar"
  glue_jar_destination = "s3://${module.code_staging.s3_bucket_name}/glue/jars/${local.glue_jar_name}"
}

data "local_file" "glue_script" {
  filename = "${var.glue_scripts_repo}/scripts/src/main/scala/scripts/${local.glue_script_name}.scala"
}

resource "aws_s3_bucket_object" "glue_script" {
  bucket = module.code_staging.s3_bucket_name
  key    = "glue/classes/${local.glue_script_name}.scala"
  source = data.local_file.glue_script.filename
  etag = filemd5(data.local_file.glue_script.filename)
  tags = var.tags
}

data "local_file" "glue_jar" {
  filename = "${var.glue_scripts_repo}/shared/target/scala-2.11/${local.glue_jar_name}"
}

resource "null_resource" "large_file_upload" {
  depends_on = [module.code_staging, data.local_file.glue_jar]
  provisioner "local-exec" {
    command = "aws s3 cp ${data.local_file.glue_jar.filename} ${local.glue_jar_destination}"
  }
  triggers = {
    hash = filemd5(data.local_file.glue_jar.filename)
  }
}

resource "aws_glue_job" "glue_etl_job" {
  name = local.glue_script_name
  role_arn = aws_iam_role.glue_job_execution_role.arn
  max_capacity = var.glue_max_capacity
  glue_version = "1.0"

  command {
    script_location = "s3://${aws_s3_bucket_object.glue_script.bucket}/${aws_s3_bucket_object.glue_script.key}"
  }

  default_arguments = {
    "--job-language" = "scala",
    "--class" = "scripts.${local.glue_script_name}",
    "--extra-jars" = local.glue_jar_destination,
    "--TempDir" = "s3://${module.code_staging.s3_bucket_name}/glue/tmp/",
    "--job-bookmark-option" = "job-bookmark-disable",
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-glue-datacatalog" = "",
    "--enable-metrics" = "",
    "--sourcePath" = "s3://${module.landing_zone.s3_bucket_name}/${var.source_path}",
    "--outputPath" = "s3://${module.trusted_zone.s3_bucket_name}/${var.output_path}",
  }
  depends_on = [null_resource.large_file_upload]
}

resource "aws_cloudwatch_log_group" "etl_glue_log_group" {
  name = "/aws/glue/${aws_glue_job.glue_etl_job.name}"
  retention_in_days = var.log_retention_days
  tags = var.tags
}

resource "aws_iam_role" "glue_job_execution_role" {
  name = "glue-job-execution-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_job_glue_service" {
  role = aws_iam_role.glue_job_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_job_get_landing" {
  name = "glue-job-get-landing-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_landing.json
  role = aws_iam_role.glue_job_execution_role.id
}

resource "aws_iam_role_policy" "glue_job_get_trusted" {
  name = "glue-job-get-trusted-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_trusted.json
  role = aws_iam_role.glue_job_execution_role.id
}

resource "aws_iam_role_policy" "glue_job_get_staging" {
  name = "glue-job-get-staging-policy"
  policy = data.aws_iam_policy_document.allow_s3_get_staging.json
  role = aws_iam_role.glue_job_execution_role.id
}

resource "aws_iam_role_policy" "glue_job_kms_access" {
  name = "glue-job-kms-access-policy"
  policy = data.aws_iam_policy_document.allow_kms_access.json
  role = aws_iam_role.glue_job_execution_role.id
}

resource "aws_iam_role_policy" "glue_job_put_trusted" {
  name = "glue-job-put-trusted-policy"
  policy = data.aws_iam_policy_document.allow_s3_put_trusted.json
  role = aws_iam_role.glue_job_execution_role.id
}

resource "aws_iam_role_policy" "glue_job_put_staging" {
  name = "glue-job-put-staging-policy"
  policy = data.aws_iam_policy_document.allow_s3_put_staging.json
  role = aws_iam_role.glue_job_execution_role.id
}
