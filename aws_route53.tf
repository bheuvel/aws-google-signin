data "aws_route53_zone" "selected" {
  count = "${var.AUTHENTICATION_DOMAIN == "" ? 0 : 1}"
  name  = "${var.AUTHENTICATION_DOMAIN}"
}

resource "aws_route53_record" "signin" {
  count   = "${var.AUTHENTICATION_DOMAIN == "" ? 0 : 1}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.AUTHENTICATION_HOST}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.google_authenticater_bucket_site.website_domain}"
    zone_id                = "${aws_s3_bucket.google_authenticater_bucket_site.hosted_zone_id}"
    evaluate_target_health = false
  }
}
