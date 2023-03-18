#################
#   TERRAFORM   #
#################

terraform {
  required_version = "~> 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }

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

##################
#   CLOUDFRONT   #
##################

resource "aws_cloudfront_distribution" "ecr" {
  aliases             = [var.domain_name]
  comment             = coalesce(var.distribution_comment, var.domain_name)
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cache_policy_id          = aws_cloudfront_cache_policy.default.id
    cached_methods           = ["GET", "HEAD"]
    default_ttl              = 0
    max_ttl                  = 0
    min_ttl                  = 0
    origin_request_policy_id = aws_cloudfront_origin_request_policy.default.id
    target_origin_id         = "ecr"
    viewer_protocol_policy   = "redirect-to-https"

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge.qualified_arn
      include_body = false
    }
  }

  origin {
    origin_id   = "ecr"
    domain_name = var.registry

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_cloudfront_cache_policy" "default" {
  name    = "ecr"
  min_ttl = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"

      headers {
        items = ["Authorization"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "default" {
  name = "ecr"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

###################
#   LAMBDA@EDGE   #
###################

data "archive_file" "package" {
  source_file = "${path.module}/src/index.js"
  output_path = "${path.module}/src/package.zip"
  type        = "zip"
}

resource "aws_iam_role" "edge" {
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

resource "aws_lambda_function" "edge" {
  description      = var.function_description
  filename         = data.archive_file.package.output_path
  function_name    = var.function_name
  handler          = "index.handler"
  publish          = true
  role             = aws_iam_role.edge.arn
  runtime          = var.function_runtime
  source_code_hash = data.archive_file.package.output_base64sha256
}

###############
#   ROUTE53   #
###############

resource "aws_route53_record" "aliases" {
  for_each = toset(["A", "AAAA"])
  name     = var.domain_name
  type     = each.value
  zone_id  = var.route53_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.ecr.domain_name
    zone_id                = aws_cloudfront_distribution.ecr.hosted_zone_id
  }
}
