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

data "aws_ssm_parameter" "default_vpc_id" {
  name = "DEFAULT_VPC_ID"
}

# モジュールを呼び出す

# Slack通知 Lambda
module "slack_notification" {
  source        = "./modules/lambda"
  name          = "slack-notification"
  function_name = "slack_notification"
  timeout       = 60
  iam_policy = {
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
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Resource" : [
          "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.this.account_id}:parameter/*"
        ]
      }
    ],
    "Version" : "2012-10-17"
  }
}

# VPC Lambda
resource "aws_subnet" "this" {
  vpc_id     = data.aws_ssm_parameter.default_vpc_id.value
  cidr_block = "172.31.48.0/20"
}

resource "aws_security_group" "vpc_lambda" {
  name        = "vpc-lambda-sg"
  description = "For VPC Lambda"
  vpc_id      = data.aws_ssm_parameter.default_vpc_id.value

  ingress {
    from_port        = 0
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

module "vpc_lambda" {
  source        = "./modules/lambda"
  name          = "vpc-lambda-test"
  function_name = "vpc_lambda_test" 
  timeout       = 60
  iam_policy = {
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
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Resource" : [
          "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.this.account_id}:parameter/*"
        ]
      },
     {
      "Effect": "Allow",
        "Action": [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource": "*"
      }
    ],
    "Version" : "2012-10-17"
  }
  in_vpc = true
  subnet_ids = [aws_subnet.this.id]
  security_group_ids = [aws_security_group.vpc_lambda.id]
}