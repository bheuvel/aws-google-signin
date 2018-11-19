output "authentication_uri" {
  value = "${ var.AUTHENTICATION_DOMAIN == "" ?  aws_s3_bucket.google_authenticater_bucket_site.website_endpoint : join("", aws_route53_record.signin.*.fqdn)  }"
}
