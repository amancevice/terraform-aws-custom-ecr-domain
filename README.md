# Custom DNS for ECR registry

[![terraform](https://img.shields.io/github/v/tag/amancevice/terraform-aws-custom-ecr-domain?color=62f&label=version&logo=terraform&style=flat-square)](https://registry.terraform.io/modules/amancevice/custom-ecr-domain/aws)
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

## How

[This post](https://httptoolkit.com/blog/docker-image-registry-facade/) describes why using a `CNAME` record alone won't work with a Docker registry.

Instead, we will use a regional API Gateway HTTP API to proxy the request through a Lambda function that responds to ANY request with a [`307` temporary redirect](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307), replacing the original request hostname with the configured ECR registry.

The redirect will preserve the method and body of the original request, allowing us to push and pull Docker images with ECR as the backend.

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
  api_name               = "ecr-proxy"
  domain_name            = "ecr.example.com"
  domain_certificate_arn = data.aws_acm_certificate.ssl.arn
  domain_zone_id         = data.aws_route53_zone.zone.id
  function_name          = "ecr-proxy"
  log_retention_in_days  = 14
}
```

## Authentication

You can use the AWS CLI to generate passwords to pass to `docker login`, but using a [credential helper](https://docs.docker.com/engine/reference/commandline/login/) is a much easier way of using Docker & ECR.

AWS provides a [tool](https://github.com/awslabs/amazon-ecr-credential-helper) to authenticate between Docker and ECR, but this helper requires repositories use the AWS-style `123456789012.dkr.ecr.us-east-1.amazonaws.com` registry names.

> _There is an open ticket ([#504](https://github.com/awslabs/amazon-ecr-credential-helper/pull/504)) to allow users to configure the offical tool to enale a default registry._

This repo provides a wrapper script that can be used with a custom registry.

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
