
terraform {
  backend "remote" {
    organization = "ccsdev"
    workspaces {
      name = "CloudChallenge"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63.0"
    }
  }
  required_version = ">= 1.0.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

// Set up the DynamoDB table. 
resource "aws_dynamodb_table" "ccddbtable" {
  name     = "CloudChallengeTable"
  hash_key = "id"
  attribute {
    name = "id"
    type = "S"
  }
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
}

// IAM policy for lambda
resource "aws_iam_role_policy" "cc_lambda_policy" {
  name = "cc_lambda_policy"
  role = aws_iam_role.cc_role.id

  policy = file("lambda_policy.json")
}

// IAM role for lambda
resource "aws_iam_role" "cc_role" {
  name = "CCrole"
  assume_role_policy = file("lambda_assume_role_policy.json")
}

// Create the lambda
resource "aws_lambda_function" "cloud_challenge_lambda" {
  function_name    = "CloudChallengeLambda"
  filename         = "lambda_payload.zip"
  role             = aws_iam_role.cc_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda_payload.zip")
}

// This begins the section on the REST API Gateway. First we'll set global API Gateway settings (see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account)
resource "aws_api_gateway_account" "global_api_account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch_role.arn
}

resource "aws_iam_role" "cloudwatch_role" {
  name = "api_gateway_cloudwatch_global_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "api_gateway_cloudwatch_global_policy"
  role = aws_iam_role.cloudwatch_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

// Now we'll set the specific API
resource "aws_api_gateway_rest_api" "cc_api" {
  name = "CloudChallengeAPI"
}

// Now the API resource
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  parent_id   = aws_api_gateway_rest_api.cc_api.root_resource_id
  path_part   = "api_resource"
}

// Then the POST method
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.cc_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

//Then the OPTIONS method
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.cc_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = "OPTIONS"

  // OPTIONS doesn't call anything so it integrates to "MOCK"
  type       = "MOCK"
  depends_on = [aws_api_gateway_method.options_method]

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

/*
*****************************************
CORS begins here. See https://mrponath.medium.com/terraform-and-aws-api-gateway-a137ee48a8ac
*****************************************
*/

// Defining the method response for OPTIONS. This has to be set before the integration response. 
resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = "OPTIONS"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.options_method]
}

// OPTIONS integration response. 
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",

    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",

    "method.response.header.Access-Control-Allow-Origin" = "'https://manach.dev'"
  }

  // See https://stackoverflow.com/a/60015289/15301692
  response_templates = {
    "application/json" = <<EOF
$input.json("$")
#set($domains = ["https://www.ccsportfolio.com", "https://ccsportfolio.com", "https://www.manach.dev"])
#set($origin = $input.params("origin"))
#if($domains.contains($origin))
#set($context.responseOverride.header.Access-Control-Allow-Origin="$origin")
#end
EOF
  }
  depends_on = [aws_api_gateway_method_response.options_method_response,
  aws_api_gateway_integration.options_integration]
}

// POST method response
resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = "POST"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  depends_on = [aws_api_gateway_method.post_method]
}

// Now we connect POST to the lambda
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.cloud_challenge_lambda.invoke_arn

}

//  POST integration response
resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_templates = {
    "application/json" = <<EOF
$input.json("$")
#set($domains = ["https://www.ccsportfolio.com", "https://ccsportfolio.com", "https://www.manach.dev"])
#set($origin = $input.params("origin"))
#if($domains.contains($origin))
#set($context.responseOverride.header.Access-Control-Allow-Origin="$origin")
#end
EOF
  }
  depends_on = [aws_api_gateway_method_response.post_method_response,
  aws_api_gateway_integration.post_integration]

}


// Then we'll give the API permission to invoke the lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloud_challenge_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cc_api.execution_arn}/*/*/*"
}


// Next is the stage
resource "aws_api_gateway_stage" "prod_stage" {
  depends_on = [aws_cloudwatch_log_group.prod_logs]
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.apideploy.id
  rest_api_id   = aws_api_gateway_rest_api.cc_api.id
}

// Now we set the log group
resource "aws_cloudwatch_log_group" "prod_logs" {
  name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.cc_api.id}/${var.stage_name}"
}

// Now set the general method settings for logging. 
resource "aws_api_gateway_method_settings" "post_settings" {
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  method_path = "*/*"
  settings {
    data_trace_enabled     = false
    metrics_enabled        = false
    logging_level          = "INFO"
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

// Now we deploy the api, with a redeploy rule in case things change in the future
resource "aws_api_gateway_deployment" "apideploy" {
  depends_on = [aws_api_gateway_integration.post_integration]
  rest_api_id = aws_api_gateway_rest_api.cc_api.id
  stage_name  = ""

  //redeploy if anything changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api_resource.id,
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.post_integration.id,
    ]))
  }
}

output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}

// Change for github actions testing purposes
