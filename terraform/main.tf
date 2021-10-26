/*
  Working on terraforming. We're going to learn by doing. May have to delete the whole folder and start over 😬
*/

// Starting with the S3 bucket.
resource "aws_s3_bucket" "manach-bucket" {
  bucket  = "manach.dev"
  acl     = "public-read"
  policy  = file("policy.json")

  website {
    index_document  = "index.html"
    error_document  = "error.html"
  }
}

// Next, we'll set the 