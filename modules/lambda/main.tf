# アカウントIDを取得するためのリソース
data "aws_caller_identity" "this" {}

# CloudWatch Logsのロググループを作成するためのリソース
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 14
}

# IAMロールとIAMポリシーを作成するためのリソース
resource "aws_iam_policy" "this" {
  name        = "terraform-lambda-${var.name}-policy"
  path        = "/"

  policy = jsonencode(
    {
      "Statement" : [
        {
          "Action" : "logs:CreateLogGroup",
          "Effect" : "Allow",
          "Resource" : "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.this.account_id}:*"
        },
        {
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.this.account_id}:log-group:/aws/lambda/${var.name}:*"
          ]
        }
      ],
      "Version" : "2012-10-17"
    }
  )
}

resource "aws_iam_role" "this" {
  name = "terraform-lambda-${var.name}-execution-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
    }
  )

  managed_policy_arns = [
    aws_iam_policy.this.arn,
  ]
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "src"
  output_path = "zip/${var.name}.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = var.name
  role             = aws_iam_role.this.arn
  handler          = "${var.function_name}.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.this.output_base64sha256
}