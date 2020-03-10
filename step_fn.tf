locals {
  camel_case_lambda = replace(var.api_lambda_name, "_", "")
  process_step = "ProcessApi"
  sourcing_lambda_state = "LAMBDA_${lower(module.api_lambda.lambda_function_name)}"
  etl_job_state = "GLUE_${aws_glue_job.glue_etl_job.name}"
}

resource "aws_sfn_state_machine" "API_sfn_state_machine" {
  name = "ApiStateMachine"
  role_arn = aws_iam_role.step_fn_role.arn
  tags = var.tags

  definition = <<EOF
{
  "Comment": "A Step fn to do API",
  "StartAt": "${local.sourcing_lambda_state}",
  "States": {
    "${local.sourcing_lambda_state}": {
      "Type": "Task",
      "Resource": "${module.api_lambda.lambda_function_arn}",
      "Parameters": {
        "input.$": "$"
      },
      "Next": "Is${local.camel_case_lambda}Complete?",
      "TimeoutSeconds": 900,
      "HeartbeatSeconds": 15,
      "Retry": [
        {
          "ErrorEquals": [ "Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }, {
          "ErrorEquals": ["States.Timeout", "HTTPError", "ConnectionError", "Timeout", "RequestException"],
          "IntervalSeconds": 2,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ]
    },
    "Is${local.camel_case_lambda}Complete?" : {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.IS_COMPLETE",
          "BooleanEquals": false,
          "Next": "${local.sourcing_lambda_state}"
        },
        {
          "Variable": "$.IS_COMPLETE",
          "BooleanEquals": true,
          "Next": "${local.process_step}"
        }
      ]
    },
    "${local.process_step}": {
      "Type": "Parallel",
      "End": true,
      "Branches": [
        {
          "StartAt": "${module.landing_zone.crawler_name}",
          "States": {
            "${module.landing_zone.crawler_name}": {
              "Type": "Task",
              "Resource": "${module.crawler_lambda.lambda_function_arn}",
              "Parameters": {
                  "CRAWLER_NAME": "${module.landing_zone.crawler_name}"
              },
              "TimeoutSeconds": ${var.timeout_seconds},
              "HeartbeatSeconds": 15,
              "Retry": [
                {
                  "ErrorEquals": [ "Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 3,
                  "BackoffRate": 2
                }, {
                  "ErrorEquals": ["States.Timeout"],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 1,
                  "BackoffRate": 1
                }
              ],
              "ResultPath": "$",
              "End": true
            }
          }
        },
        {
          "StartAt": "${local.etl_job_state}",
          "States": {
            "${local.etl_job_state}": {
              "Type": "Task",
              "Resource": "arn:aws:states:::glue:startJobRun.sync",
              "Parameters": {
                "JobName": "${aws_glue_job.glue_etl_job.name}"
              },
              "Next": "${module.trusted_zone.crawler_name}"
            },
            "${module.trusted_zone.crawler_name}": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "Resource": "${module.crawler_lambda.lambda_function_arn}",
              "Parameters": {
                "Payload": {
                  "CRAWLER_NAME": "${module.trusted_zone.crawler_name}"
                }
              },
              "TimeoutSeconds": ${var.timeout_seconds},
              "HeartbeatSeconds": 15,
              "Retry": [
                {
                  "ErrorEquals": [ "Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 3,
                  "BackoffRate": 2
                }, {
                  "ErrorEquals": ["States.Timeout"],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 1,
                  "BackoffRate": 1
                }
              ],
              "ResultPath": "$",
              "Next": "${module.view_lambda.lambda_function_name}"
            },
            "${module.view_lambda.lambda_function_name}": {
              "Type": "Task",
              "Resource": "${module.view_lambda.lambda_function_arn}",
              "TimeoutSeconds": ${var.timeout_seconds},
              "HeartbeatSeconds": 15,
              "Parameters": {
                "SQL_QUERY_FILES": "${var.view_list}",
                "TABLENAME": "${var.output_path}",
                "ATHENA_DATABASE": "${module.trusted_zone.glue_catalog_database_name}",
                "WORKGROUP": "${aws_athena_workgroup.DataConsumers.name}"
              },
              "Retry": [
                {
                  "ErrorEquals": [ "Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 6,
                  "BackoffRate": 2
                }, {
                  "ErrorEquals": ["States.Timeout", "SSHException"],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 1,
                  "BackoffRate": 1
                }
              ],
              "ResultPath": "$",
              "End": true
            }
          }
        }
      ]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "step_fn_trigger" {
  name = "run-${aws_sfn_state_machine.API_sfn_state_machine.name}"
  schedule_expression = var.cron_schedule
  is_enabled = true
  role_arn = aws_iam_role.events_trigger_role.arn
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "step_fn" {
  rule      = aws_cloudwatch_event_rule.step_fn_trigger.name
  role_arn = aws_iam_role.events_trigger_role.arn
  arn       = "arn:aws:states:${var.aws_region}:${var.account_id}:stateMachine:${aws_sfn_state_machine.API_sfn_state_machine.name}"
  input = <<DOC
{
  "APIKEY": "${var.api_key}",
  "URL": "${var.api_url}",
  "PAGESIZE": ${var.api_page_size},
  "PAGE_NUMBER": 1,
  "DATA_KEY": "${var.api_data_key}",
  "IS_COMPLETE": false,
  "LANDING_BUCKET": "${module.landing_zone.s3_bucket_name}",
  "TABLE_NAME": "${var.api_table_name}"
}
DOC
}

resource "aws_iam_role" "step_fn_role" {
  name = "StepFunctionRole"
  tags = var.tags
  assume_role_policy = data.aws_iam_policy_document.states_assume.json
}

resource "aws_iam_role_policy" "lambda_trigger_policy" {
  name = "lambda-execution-trigger"
  role = aws_iam_role.step_fn_role.id
  policy = data.aws_iam_policy_document.allow_lambda_execution.json
}

resource "aws_iam_role_policy" "glue_trigger_policy" {
  name = "glue-execution-trigger"
  role = aws_iam_role.step_fn_role.id
  policy = data.aws_iam_policy_document.allow_glue_job_execution.json
}

resource "aws_iam_role" "events_trigger_role" {
  name = "cloudwatch-event-trigger"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_events_assume.json
  tags = var.tags
}

resource "aws_iam_role_policy" "step_fn_allow_execute" {
  name = "event-trigger-${lower(aws_sfn_state_machine.API_sfn_state_machine.name)}-policy"
  role = aws_iam_role.events_trigger_role.id
  policy =  data.aws_iam_policy_document.allow_states_execution.json
}
