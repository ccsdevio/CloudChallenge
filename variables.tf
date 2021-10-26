variable "aws_region" {
  type          = string 
  description   = "The aws region where everything goes"
  default       = "us-east-1"
}

variable "site_domain" {
  type        = string
  description = "The domain name for the project"
}