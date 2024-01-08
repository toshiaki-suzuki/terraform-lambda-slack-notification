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

module "slack_notification" {
  source = "./modules/lambda"
  name   = "slack-notification"
  function_name = "slack_notification"
}