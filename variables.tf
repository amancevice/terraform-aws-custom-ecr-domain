###############
#   GENERAL   #
###############

variable "log_retention_in_days" {
  type        = number
  description = "ECR custom log retention in days"
  default     = 14
}

variable "tags" {
  type        = map(string)
  description = "ECR custom domain tags"
  default     = null
}

###########
#   API   #
###########

variable "api_auto_deploy" {
  type        = bool
  description = "API auto deploy"
  default     = true
}

variable "api_description" {
  type        = string
  description = "API description"
  default     = "ECR custom domain proxy"
}

variable "api_log_format" {
  type        = map(string)
  description = "ECR custom domain proxy API log format"
  default = {
    httpMethod              = "$context.httpMethod"
    integrationErrorMessage = "$context.integrationErrorMessage"
    ip                      = "$context.identity.sourceIp"
    path                    = "$context.path"
    protocol                = "$context.protocol"
    requestId               = "$context.requestId"
    requestTime             = "$context.requestTime"
    responseLength          = "$context.responseLength"
    routeKey                = "$context.routeKey"
    status                  = "$context.status"
  }
}

variable "api_name" {
  type        = string
  description = "ECR custom domain proxy API name"
}

variable "api_stage_description" {
  type        = string
  description = "ECR custom domain proxy API stage description"
  default     = "ECR custom domain proxy API stage"
}

###########
#   DNS   #
###########

variable "domain_certificate_arn" {
  type        = string
  description = "ECR custom domain proxy API custom domain ACM certificate ARN"
}

variable "domain_name" {
  type        = string
  description = "ECR custom domain proxy API custom domain"
}

variable "domain_zone_id" {
  type        = string
  description = "ECR custom domain proxy API Route53 hosted zone ID"
}

####################
#   PROXY LAMBDA   #
####################

variable "function_description" {
  description = "ECR custom domain proxy function description"
  type        = string
  default     = "Enhance Docker requests for ECR"
}

variable "function_name" {
  description = "ECR custom domain proxy function name"
  type        = string
}

variable "function_role_name" {
  description = "ECR custom domain proxy role name"
  type        = string
  default     = null
}

variable "function_runtime" {
  description = "ECR custom domain proxy function runtime"
  type        = string
  default     = "nodejs18.x"
}
