# CloudChallenge

My build of Forrest Brazeal's Cloud Resume Challenge. 

## Overview
The Cloud Resume Challenge, created by Forrest Brazeal, lays out a spec to demonstrate competence with AWS serverless systems, simple CI/CD, and automated testing. 

This project contains several parts:
## Static Resume Website
* Custom domain served in HTTPS using CloudFront
* HTML, CSS, and JavaScript stored in S3
## Simple Dynamic Content
* Visitor counter implemented with API Gateway, Lambda, and DynamoDB
## Automated Testing, IaC, and CI/CD
* End-to-end tests with Cypress
* IaC with Terraform
* Simple CI/CD with GitHub Actions, which automates testing runs, Terraform runs, S3 updates, and CloudFront invalidation


More information can be found [here.](https://cloudresumechallenge.dev/docs/faq/)
