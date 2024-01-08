terraform {
 backend "s3" {
   bucket  = "akis-tfstate-bucket"
   region  = "ap-northeast-1"
   key     = "dir/terraform-lambda-slack-notification.tfstate"
   encrypt = false
 }
}

provider "aws" {
  region = "ap-northeast-1"
}

# アカウントIDを取得するためのリソース
data "aws_caller_identity" "this" {}

# モジュールを呼び出す
module "slack_notification" {
  source = "./modules/lambda"
  name   = "slack-notification"
  function_name = "slack_notification"
  timeout = 60
  iam_policy =     {
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
            "arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.this.account_id}:log-group:/aws/lambda/slack-notification:*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ssm:GetParameter",
            "ssm:GetParameters"
          ],
          "Resource": [
            "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.this.account_id}:parameter/*"
          ]
        }
      ],
      "Version" : "2012-10-17"
    }
}