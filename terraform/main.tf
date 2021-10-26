/*
  Working on terraforming. We're going to learn by doing. May have to delete the whole folder and start over 😬
*/

provider "aws" {
  region = var.aws_region
}

// Starting with the S3 bucket. Using https://learn.hashicorp.com/tutorials/terraform/cloudflare-static-website?in=terraform/aws
resource "aws_s3_bucket" "site" {
  bucket  = var.site_domain
  acl     = "public-read"
  policy  = aws_s3_bucket_policy.public_read
  
  website {
    index_document  = "index.html"
    error_document  = "error.html"
  }
}

resource "aws_s3_bucket" "www" {
  bucket  = "www.${var.site_domain}"
  acl     = "private"
  policy  = ""

  website {
    redirect_all_requests_to = "https://${var.site_domain}"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket  = aws_s3_bucket.site.id 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*"
        ]
      },
    ]
  })
}