variable "acm_certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "domain_name" {
  description = "Custom DNS name for ECR registry"
  type        = string
}

variable "distribution_comment" {
  description = "CloudFront distribution comment"
  type        = string
  default     = null
}

variable "function_description" {
  description = "Lambda@Edge function description"
  type        = string
  default     = "Enhance Docker requests for ECR"
}

variable "function_name" {
  description = "Lambda@Edge function name"
  type        = string
}

variable "function_role_name" {
  description = "Lambda@Edge role name"
  type        = string
  default     = null
}

variable "function_runtime" {
  description = "Lambda@Edge function runtime"
  type        = string
  default     = "nodejs18.x"
}

variable "registry" {
  description = "ECR registry name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}
