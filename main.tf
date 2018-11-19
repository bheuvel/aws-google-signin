provider "aws" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_string" "bucket_suffix" {
  length = 8
  upper = false
  special = false
}

locals {
  s3_bucketname = "${var.AUTHENTICATION_DOMAIN == "" ? "google-authenticater-${random_string.bucket_suffix.result}" : "${var.AUTHENTICATION_HOST}.${var.AUTHENTICATION_DOMAIN}"}"
  lambda_zip = "lambda.zip"
  awsconfig = <<EOF
window.config = {
    roleArn: "${aws_iam_role.google_authentication.arn}",
    region: "${data.aws_region.current.name}",
    apiGatewayUrl: "${join("/", slice(split("/", aws_api_gateway_deployment.token_bridge_api_deployment.invoke_url), 0, length(split("/", aws_api_gateway_deployment.token_bridge_api_deployment.invoke_url))-1))}",
    apiGatewayPath: "/${join("/",slice(split("/", aws_api_gateway_deployment.token_bridge_api_deployment.invoke_url), length(split("/", aws_api_gateway_deployment.token_bridge_api_deployment.invoke_url))-1, length(split("/", aws_api_gateway_deployment.token_bridge_api_deployment.invoke_url))))}",
}
EOF
}

resource "aws_iam_role" "google_authentication" {
  name = "Google_Authenticated_Users"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "accounts.google.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "accounts.google.com:aud": "${var.GOOGLE_CLIENT_ID}",
          "accounts.google.com:sub": [
            "${var.GOOGLE_ID}"
          ]
        }
      }
    }
  ]
}
EOF
}
