data "aws_iam_policy_document" "cloudwatch_events_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "glue_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "states_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow_athena_query_execution" {
  statement {
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetWorkgroup",
      "athena:GetQueryResults"
    ]

    resources = [
      "arn:aws:athena:${var.aws_region}:${var.account_id}:workgroup/${aws_athena_workgroup.DataConsumers.name}"
    ]
  }
  statement {
    actions = [
      "glue:GetPartitions"
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:database/${module.trusted_zone.glue_catalog_database_name}",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:table/${module.trusted_zone.glue_catalog_database_name}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_comprehend_detection" {
  statement {
    actions = [
      "comprehend:DetectEntities"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_glue_crawler_execution" {
  statement {
    actions = [
      "glue:StartCrawler",
      "glue:ListCrawlers",
      "glue:GetCrawler"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_glue_table_creation" {
  statement {
    actions = [
      "glue:GetTable",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:UpdateTable"
    ]

    resources = [
      "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:database/${module.trusted_zone.glue_catalog_database_name}",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:table/${module.trusted_zone.glue_catalog_database_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "allow_glue_job_execution" {
  statement {
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "allow_kms_access" {
  statement {
    actions = [
      "kms:ListAliases",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "*",
      aws_kms_key.s3_encryption_key.arn
    ]
  }
  statement {
    actions = [
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.s3_encryption_key.arn
    ]
  }
}

data "aws_iam_policy_document" "allow_lambda_execution" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:*"
    ]
  }
}

data "aws_iam_policy_document" "allow_logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "aws_iam_policy_document" "allow_network_interface_creation" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_s3_athena_results" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetBucketLocation",
    ]

    resources = [
      module.athena_queries.s3_bucket_arn,
      "${module.athena_queries.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_get_analytics" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:GetEncryptionConfiguration"
    ]

    resources = [
      module.analytics_zone.s3_bucket_arn,
      "${module.analytics_zone.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_get_landing" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:GetEncryptionConfiguration"
    ]

    resources = [
      module.landing_zone.s3_bucket_arn,
      "${module.landing_zone.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_get_staging" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:GetEncryptionConfiguration"
    ]

    resources = [
      module.code_staging.s3_bucket_arn,
      "${module.code_staging.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_get_trusted" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:GetEncryptionConfiguration",
    ]

    resources = [
      module.trusted_zone.s3_bucket_arn,
      "${module.trusted_zone.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_put_analytics" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutEncryptionConfiguration",
      "s3:DeleteObject"
    ]

    resources = [
      module.analytics_zone.s3_bucket_arn,
      "${module.analytics_zone.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_put_landing" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutEncryptionConfiguration",
    ]
    resources = [
      module.landing_zone.s3_bucket_arn,
      "${module.landing_zone.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_put_staging" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutEncryptionConfiguration",
      "s3:DeleteObject"
    ]

    resources = [
      module.code_staging.s3_bucket_arn,
      "${module.code_staging.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_s3_put_trusted" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutEncryptionConfiguration",
      "s3:DeleteObject"
    ]

    resources = [
      module.trusted_zone.s3_bucket_arn,
      "${module.trusted_zone.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "allow_states_execution" {
  statement {
    actions = [
      "states:StartExecution"
    ]
    resources = [
      "arn:aws:states:${var.aws_region}:${var.account_id}:stateMachine:${aws_sfn_state_machine.API_sfn_state_machine.name}"
    ]
  }
}
