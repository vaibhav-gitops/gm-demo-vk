provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

locals {
  api_name         = "example-api"
  lambda_role_name = "TestLambdaExecutionRole"
  tags = {
    Project = "GitMoxi"
    Owner   = "User"
  }
}

################################################################################
# IAM Role for Lambda
################################################################################

resource "aws_iam_role" "lambda_exec" {
  name = local.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

################################################################################
# API Gateway
################################################################################

resource "aws_apigatewayv2_api" "api" {
  name          = local.api_name
  protocol_type = "HTTP"

  tags = local.tags
}

variable "lambdaAlias" {
  type        = string
  default     = "PROD"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  stage_variables = {
    lambdaAlias = var.lambdaAlias
  }

  tags = local.tags
}

resource "aws_apigatewayv2_route" "test_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /test"
}
