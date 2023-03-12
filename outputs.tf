###############
#   OUTPUTS   #
###############

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.ecr.id
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.ecr.domain_name
}
