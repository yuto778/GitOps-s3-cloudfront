output "s3_website_url" {
  value = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}
