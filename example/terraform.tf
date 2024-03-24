###########
#   AWS   #
###########

provider "aws" {
  region = "us-west-2"

  default_tags { tags = { Name = "custom-ecr-domain" } }
}

##############
#   LOCALS   #
##############

locals {
  region             = data.aws_region.current.name
  function_name      = "${replace(var.domain_name, ".", "-")}-ecr-redirect"
  function_role_name = "${local.region}-${local.function_name}"
}

############
#   DATA   #
############

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#########################
#   CUSTOM ECR DOMAIN   #
#########################

variable "domain_name" { type = string }

data "aws_acm_certificate" "ssl" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "zone" {
  name = "${var.domain_name}."
}

module "custom-ecr-domain" {
  source = "./.."

  domain_name            = "ecr.${var.domain_name}"
  domain_certificate_arn = data.aws_acm_certificate.ssl.arn
  domain_zone_id         = data.aws_route53_zone.zone.id
  api_name               = "ecr.${var.domain_name}"
  function_name          = local.function_name
  function_role_name     = local.function_role_name
  log_retention_in_days  = 14
}

############################
#   CUSTOM ECR REPO TEST   #
############################

resource "aws_ecr_repository" "test" {
  name = "test"
}
