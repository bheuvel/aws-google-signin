
resource "aws_s3_bucket" "google_authenticater_bucket_site" {
  bucket = "${local.s3_bucketname}"
  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
  {
    "Sid": "bucket_policy_site_main",
    "Action": [
      "s3:GetObject"
    ],
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::${local.s3_bucketname}/*",
    "Principal": "*",
    "Condition": {
      "IpAddress": {
        "aws:SourceIp": "0.0.0.0/0"
      }
    }
  }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "local_file" "index_html" {
    filename = "aws-google-oauth2-example/index.html"
}
resource "aws_s3_bucket_object" "index" {
  bucket = "${aws_s3_bucket.google_authenticater_bucket_site.id}"
  key    = "index.html"
  content_type = "text/html"
  content = "${replace(data.local_file.index_html.content, "YOUR-CLIENT-ID", "${var.GOOGLE_CLIENT_ID}")}"
  etag   = "${md5(replace(data.local_file.index_html.content, "YOUR-CLIENT-ID", "${var.GOOGLE_CLIENT_ID}"))}"
}
resource "aws_s3_bucket_object" "awsconfig" {
  bucket = "${aws_s3_bucket.google_authenticater_bucket_site.id}"
  key = "awsconfig.js"
  content_type = "text/javascript"
  content = "${local.awsconfig}"
}
resource "aws_s3_bucket_object" "authentication" {
  bucket = "${aws_s3_bucket.google_authenticater_bucket_site.id}"
  key = "authentication.js"
  content_type = "text/javascript"
  source = "aws-google-oauth2-example/authentication.js"
  etag = "${md5(file("aws-google-oauth2-example/authentication.js"))}"
}
