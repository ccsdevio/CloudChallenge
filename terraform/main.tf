terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_dynamodb_table" "ccddbtable" {
  name            = "CloudChallengeTable"
  hash_key        = "id"
  attribute {
    name = "id"
    type = "S"
  }
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1
}

resource "aws_iam_role_policy" "cc_lambda_policy" {
  name = "cc_lambda_policy"
  role = aws_iam_role.cc_role.id

  policy = file("policy.json")
}

resource "aws_iam_role" "cc_role" {
  name = "CCrole"

  assume_role_policy = file("assume_role_policy.json")

}

resource "aws_lambda_function" "cloud_challenge_lambda" {

  function_name = "CloudChallengeLambda"
  filename      = "lambda_payload.zip"
  role          = aws_iam_role.cc_role.arn
  handler       = "lambda_function.lambda_handler" 
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("lambda_payload.zip")

}

resource "aws_api_gateway_rest_api" "cc_api" {
  name = "CloudChallengeAPI"

}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  parent_id   = aws_api_gateway_rest_api.cc_api.root_resource_id
  path_part   = "api_resource"

}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.cc_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "lambda_int" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS" 
  uri                     = aws_lambda_function.cloud_challenge_lambda.invoke_arn

}

resource "aws_api_gateway_deployment" "apideploy" {
  depends_on  = [aws_api_gateway_integration.lambda_int]

  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloud_challenge_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cc_api.execution_arn}/*/*/*"

}

output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}