#
# resource "aws_iam_role_policy" "allow_cloudwatch_logging" {
#   name = "Allow_CloudWatch_Logging"
#   role = "${aws_iam_role.lambda_exec.id}"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#   {
#     "Effect": "Allow",
#     "Action": "logs:CreateLogGroup",
#     "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
#   },
#   {
#     "Effect": "Allow",
#     "Action": [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ],
#     "Resource": [
#       "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/google:*"
#     ]
#   }
#   ]
# }
# EOF
# }
resource "aws_iam_role" "lambda_exec" {
  name = "Basic_Lambda_Execution"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow"
  }
]
}
EOF
}

# Watch source file for new data...
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "aws-google-oauth2-example/lambda"
    output_path = "${local.lambda_zip}"
}

resource "aws_lambda_function" "token_bridge_lambda" {
  filename = "${local.lambda_zip}"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  function_name = "token_bridge_lambda"
  role = "${aws_iam_role.lambda_exec.arn}"
  description = "Return sign-in token"
  handler = "index.handler"
  runtime = "nodejs6.10"
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.token_bridge_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${local.post_arn}"
}
