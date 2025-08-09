terraform {
  backend "s3" {
    bucket         = "terraform-state-215ad062"
    key            = "gitops-s3-cloudfront/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock-215ad062"
    encrypt        = true
  }
}
