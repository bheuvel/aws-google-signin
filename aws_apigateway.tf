locals {
  options_arn = "${element(split("/", "${aws_api_gateway_deployment.token_bridge_api_deployment.execution_arn}"),0)}/*/OPTIONS/"
  post_arn = "${element(split("/", "${aws_api_gateway_deployment.token_bridge_api_deployment.execution_arn}"),0)}/*/POST/"
}

resource "aws_iam_role_policy" "invoke-api" {
  name = "Allow_Invoke_API_for_Google_authentication"
  role = "${aws_iam_role.google_authentication.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": "execute-api:Invoke",
    "Resource": [
      "${local.post_arn}",
      "${local.options_arn}"
    ]
  }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "token_bridge_api" {
  name        = "TokenBridge"
  description = "Provide access to the AWS sign-in token"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "token_bridge_api_deployment" {
  depends_on          = [
    "aws_api_gateway_integration_response.gateway_post_response",
    "aws_api_gateway_integration_response.gateway_option_response",
  ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  stage_name          = "prod"
  # https://github.com/terraform-providers/terraform-provider-aws/issues/162
  stage_description   = "${md5(file("aws_apigateway.tf"))}"
}

resource "aws_api_gateway_method" "gateway_options_method" {
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "OPTIONS"
  authorization       = "NONE"
  request_parameters  = {}
}
resource "aws_api_gateway_integration" "options_integration_request" {
  depends_on          = [ "aws_api_gateway_method.gateway_options_method" ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_method.gateway_options_method.resource_id}"
  http_method         = "${aws_api_gateway_method.gateway_options_method.http_method}"
  type                = "MOCK"
  request_templates   = { "application/json" = "{\"statusCode\": 200}" }
}
resource "aws_api_gateway_integration_response" "gateway_option_response" {
  depends_on          = [ "aws_api_gateway_integration.options_integration_request" ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "${aws_api_gateway_method.gateway_options_method.http_method}"
  status_code         = "${aws_api_gateway_method_response.gateway_options_response_200.status_code}"
  response_templates  = { "application/json" = "" }
  response_parameters = "${var.options_integration_response_parameters}"
}
resource "aws_api_gateway_method_response" "gateway_options_response_200" {
  depends_on          = [ "aws_api_gateway_method.gateway_options_method" ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "${aws_api_gateway_method.gateway_options_method.http_method}"
  status_code         = "200"
  response_models     = { "application/json" = "Empty" }
  response_parameters = "${var.options_response_headers}"
}


resource "aws_api_gateway_method" "gateway_post_method" {
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "POST"
  authorization       = "AWS_IAM"
  request_parameters  = {}
}
resource "aws_api_gateway_integration" "post_integration_request" {
  depends_on          = [ "aws_api_gateway_method.gateway_post_method" ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "${aws_api_gateway_method.gateway_post_method.http_method}"
  type                = "AWS_PROXY"
  integration_http_method = "POST"
  uri                 = "${aws_lambda_function.token_bridge_lambda.invoke_arn}"
  content_handling    = "CONVERT_TO_TEXT"
}
resource "aws_api_gateway_integration_response" "gateway_post_response" {
  depends_on          = [ "aws_api_gateway_integration.post_integration_request" ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "${aws_api_gateway_method.gateway_post_method.http_method}"
  status_code         = "${aws_api_gateway_method_response.gateway_post_response_200.status_code}"
  response_templates  = { "application/json" = "" }
  response_parameters = "${var.post_integration_response_parameters}"
}
resource "aws_api_gateway_method_response" "gateway_post_response_200" {
  depends_on          = [ "aws_api_gateway_method.gateway_post_method" ]
  rest_api_id         = "${aws_api_gateway_rest_api.token_bridge_api.id}"
  resource_id         = "${aws_api_gateway_rest_api.token_bridge_api.root_resource_id}"
  http_method         = "${aws_api_gateway_method.gateway_post_method.http_method}"
  status_code         = "200"
  response_models     = { "application/json" = "Empty" }
  response_parameters = "${var.post_response_headers}"
}

variable "options_response_headers" {
   type = "map"
   default = {
        "method.response.header.Access-Control-Allow-Headers" = true
        "method.response.header.Access-Control-Allow-Methods" = true
        "method.response.header.Access-Control-Allow-Origin" = true
     }
}
variable "options_integration_response_parameters" {
   type = "map"
   default = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Amz-User-Agent,X-Amz-Security-Token,X-Api-Key'"
        "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
     }
}
variable "post_response_headers" {
   type = "map"
   default = {
        "method.response.header.Access-Control-Allow-Origin" = true
     }
}
variable "post_integration_response_parameters" {
   type = "map"
   default = {
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
     }
}
