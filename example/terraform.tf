#################
#   TERRAFORM   #
#################

terraform {
  required_version = "~> 1.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.3"
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

provider "aws" {
  region = "us-east-1"

  default_tags { tags = { Name = "custom-ecr-domain" } }
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"

  default_tags { tags = { Name = "custom-ecr-domain" } }
}

data "aws_caller_identity" "current" {}

#########################
#   CUSTOM ECR DOMAIN   #
#########################

data "aws_acm_certificate" "ssl" {
  domain   = "mancevice.dev"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "zone" {
  name = "mancevice.dev."
}

module "custom-ecr-domain" {
  source = "./.."

  domain_name         = "ecr.mancevice.dev"
  function_name       = "mancevice-dev-ecr-edge"
  registry            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-2.amazonaws.com"
  acm_certificate_arn = data.aws_acm_certificate.ssl.arn
  route53_zone_id     = data.aws_route53_zone.zone.id
}

############################
#   CUSTOM ECR REPO TEST   #
############################

resource "aws_ecr_repository" "test" {
  provider = aws.us-west-2
  name     = "test"
}
