output "api" {
  description = "API Gateway API"
  value       = aws_apigatewayv2_api.api
}

output "api_domain" {
  description = "API Gateway custom domain"
  value       = aws_apigatewayv2_domain_name.api
}

output "api_stage" {
  description = "API Gateway stage"
  value       = aws_apigatewayv2_stage.default
}

output "proxy" {
  description = "Lambda function"
  value       = aws_lambda_function.proxy
}

output "log_groups" {
  description = "CloudWatch log groups"
  value = {
    api   = aws_cloudwatch_log_group.api
    proxy = aws_cloudwatch_log_group.proxy
  }
}
