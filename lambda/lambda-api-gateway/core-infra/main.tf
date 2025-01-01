provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

################################################################################
# Locals and Variables
################################################################################

locals {
  api_name         = "example-api"
  lambda_role_name = "TestLambdaExecutionRole"
  blue_lambda_zip_file  = "blue_function.zip"
  green_lambda_zip_file  = "green_function.zip"
  lambda_runtime   = "python3.8"
  tags = {
    Project = "GitMoxi"
    Owner   = "User"
  }
}

variable "lambdaAlias" {
  type        = string
  default     = "PROD"
}

################################################################################
# IAM Role for Lambda Execution
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

################################################################################
# S3 Bucket for Lambda Deployment
################################################################################

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-function-deployment-bucket-${random_id.suffix.hex}"

  tags = local.tags
}

################################################################################
# Package Lambda Code and Upload to S3
################################################################################

# Unique identifier for the S3 bucket
resource "random_id" "suffix" {
  byte_length = 4
}

# Upload the Lambda zip file to S3
resource "aws_s3_object" "blue_lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = local.blue_lambda_zip_file
  source = local.blue_lambda_zip_file
  etag   = filemd5(local.blue_lambda_zip_file)
}

resource "aws_s3_object" "green_lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = local.green_lambda_zip_file
  source = local.green_lambda_zip_file
  etag   = filemd5(local.blue_lambda_zip_file)
}

################################################################################
# Outputs
################################################################################

output "api_id" {
  value = aws_apigatewayv2_api.api.id
}

output "route_id" {
  value = aws_apigatewayv2_route.test_route.id
}

output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.lambda_bucket.id
}

output "s3_object_blue_key" {
  value = aws_s3_object.blue_lambda_zip.key
}

output "s3_object_green_key" {
  value = aws_s3_object.green_lambda_zip.key
}