# Custom DNS for ECR registry

> This repo is based on and expands [naftulikay/terraform-aws-private-ecr-domain](https://github.com/naftulikay/terraform-aws-private-ecr-domain)

Set up a custom DNS entry for a ECR.

Instead of:

```bash
docker pull 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-repo
```

Use CloudFront and Lambda@Edge to alias your registry with DNS:

```bash
docker pull ecr.example.com/my-repo
```

> Pushing Docker images to ECR does not appear to be working

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
  source              = "amancevice/custom-ecr-domain/aws"
  domain_name         = "ecr.example.com"
  function_name       = "custom-ecr-edge"
  registry            = "123456789012.dkr.ecr.us-west-2.amazonaws.com"
  acm_certificate_arn = data.aws_acm_certificate.ssl.arn
  route53_zone_id     = data.aws_route53_zone.zone.id
}
```

## Credential Helper

AWS provides a [credential helper](https://github.com/awslabs/amazon-ecr-credential-helper) tool to authenticate between Docker and ECR, but this helper requires repositories use the AWS-style `123456789012.dkr.ecr.us-east-1.amazonaws.com` registry names.

This repo provides a bash wrapper that can be used with a custom registry.

To use the credential helper:

  - Clone this repo
  - Copy `bin/docker-credential-ecr-custom` somewhere on your `$PATH` (eg, `/usr/local/bin`)
  - Update your Docker config `credHelpers` section:

```json
{
  "credHelpers": {
    "ecr.example.com": "ecr-custom"
  }
}

```
