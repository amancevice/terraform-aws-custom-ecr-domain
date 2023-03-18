# Custom DNS for ECR registry

[![terraform](https://img.shields.io/github/v/tag/amancevice/terraform-aws-custom-ecr-domain?color=62f&label=version&logo=terraform&style=flat-square)](https://registry.terraform.io/modules/amancevice/serverless-pypi/aws)
[![test](https://img.shields.io/github/actions/workflow/status/amancevice/terraform-aws-custom-ecr-domain/test.yml?logo=github&style=flat-square)](https://github.com/amancevice/terraform-aws-custom-ecr-domain/actions/workflows/test.yml)

Set up a custom DNS entry for a ECR.

Instead of:

```bash
docker pull 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-repo
```

Use API Gateway HTTP APIs and Lambda to alias your registry with DNS:

```bash
docker pull ecr.example.com/my-repo
```

## Usage

See the [example](./example) directory for an example project.

```terraform
data "aws_acm_certificate" "ssl" {
  domain   = "example.com"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "zone" {
  name = "example.com."
}

module "custom-ecr-domain" {
  source                 = "amancevice/custom-ecr-domain/aws"
  domain_name            = "ecr.example.com"
  domain_certificate_arn = data.aws_acm_certificate.ssl.arn
  domain_zone_id         = data.aws_route53_zone.zone.id
  api_name               = "ecr.example.com"
  function_name          = "ecr-redirect"
  log_retention_in_days  = 14
}
```

## Credential Helper

AWS provides a [credential helper](https://github.com/awslabs/amazon-ecr-credential-helper) tool to authenticate between Docker and ECR, but this helper requires repositories use the AWS-style `123456789012.dkr.ecr.us-east-1.amazonaws.com` registry names.

This repo provides a bash wrapper that can be used with a custom registry.

To use the credential helper:

- Clone this repo
- Copy `bin/docker-credential-ecr-custom` somewhere on your `$PATH` (eg, `/usr/local/bin`)
- Create the config file `~/.ecr/custom.json` with mappings of your custom domains and ECR registries
- Update your Docker config `credHelpers` section to use `ecr-custom`

Example `~/.ecr/custom.json`:

```json
{
  "ecr.example.com": "123456789012.dkr.ecr.us-east-1.amazonaws.com"
}
```

Example `~/.docker/config.json` snippet:

```json
{
  "credHelpers": {
    "ecr.example.com": "ecr-custom"
  }
}
```
