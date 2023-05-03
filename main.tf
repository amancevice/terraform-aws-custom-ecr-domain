#################
#   TERRAFORM   #
#################

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

###########
#   AWS   #
###########

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###################
#   API GATEWAY   #
###################

resource "aws_apigatewayv2_api" "api" {
  description                  = var.api_description
  disable_execute_api_endpoint = true
  name                         = var.api_name
  protocol_type                = "HTTP"
  tags                         = var.tags
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.domain_name
  stage       = aws_apigatewayv2_stage.default.name
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.domain_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.proxy.id}"
}

resource "aws_apigatewayv2_integration" "proxy" {
  api_id                 = aws_apigatewayv2_api.api.id
  description            = var.function_description
  integration_method     = "POST"
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.proxy.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  auto_deploy = var.api_auto_deploy
  description = var.api_description
  name        = "$default"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format          = jsonencode(var.api_log_format)
  }

  lifecycle {
    ignore_changes = [deployment_id]
  }
}

###########
#   DNS   #
###########

resource "aws_route53_record" "records" {
  for_each       = toset(["A", "AAAA"])
  name           = aws_apigatewayv2_domain_name.api.domain_name
  set_identifier = data.aws_region.current.name
  type           = each.key
  zone_id        = var.domain_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
  }

  latency_routing_policy {
    region = data.aws_region.current.name
  }
}

##############
#   LAMBDA   #
##############

locals {
  default_ecr_regstry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  ecr_registry        = coalesce(var.ecr_regisitry, local.default_ecr_regstry)
}

data "archive_file" "proxy" {
  source_file = "${path.module}/src/index.js"
  output_path = "${path.module}/src/package.zip"
  type        = "zip"
}

resource "aws_iam_role" "proxy" {
  name = coalesce(var.function_role_name, var.function_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Action = "sts:AssumeRole"

      Principal = {
        Service = [
          "edgelambda.amazonaws.com",
          "lambda.amazonaws.com",
        ]
      }
    }
  })

  inline_policy {
    name = "logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = {
        Effect   = "Allow"
        Action   = "logs:*"
        Resource = "*"
      }
    })
  }
}

resource "aws_lambda_function" "proxy" {
  architectures    = ["arm64"]
  description      = var.function_description
  filename         = data.archive_file.proxy.output_path
  function_name    = var.function_name
  handler          = "index.handler"
  role             = aws_iam_role.proxy.arn
  runtime          = var.function_runtime
  source_code_hash = data.archive_file.proxy.output_base64sha256

  environment {
    variables = { AWS_ECR_REGISTRY = local.ecr_registry }
  }
}

resource "aws_lambda_permission" "proxy" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/$default/ANY/{proxy+}"
}


############
#   LOGS   #
############

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigatewayv2/${aws_apigatewayv2_api.api.name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_log_group" "proxy" {
  name              = "/aws/lambda/${aws_lambda_function.proxy.function_name}"
  retention_in_days = var.log_retention_in_days
}
