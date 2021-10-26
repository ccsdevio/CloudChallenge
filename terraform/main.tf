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

resource "aws_iam_role" "iam_for_cloud_challenge_lambda" {
  name = "iamForCloudChallengeLambda"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:UpdateItem",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "cloud_challenge_lambda" {
  filename        = "lambda_payload.zip"
  function_name   = "cloudChallengeLambda"
  role            = aws_iam_role.iam_for_cloud_challenge_lambda.arn
  handler         = "lambda_function.py"

  source_code_hash = filebase64sha256("lambda_payload.zip")

  runtime = "python3.9"

}