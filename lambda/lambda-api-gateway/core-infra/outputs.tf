################################################################################
# Outputs
################################################################################

output "api_id" {
  value = aws_apigatewayv2_api.api.id
}

output "test_route_id" {
  value = aws_apigatewayv2_route.test_route.id
}

output "lambda_exec_role_arn" {
  value       = aws_iam_role.lambda_exec.arn
}