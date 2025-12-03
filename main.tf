terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2" # можешь поменять регион, если нужно
}

# === Настраиваем название бакета ===
# ВАЖНО: имя должно быть уникальным по всему миру.
# Например: zheenbek-portfolio-123
variable "bucket_name" {
  type        = string
  description = "my-portfolio-jim"
}

# === Сам бакет ===
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Project = "static-website-terraform"
  }
}

# === Управление владением объектов (новые требования S3) ===
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# === Public access block (выключаем блокировку публичного доступа) ===
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# === Включаем статику (Static Website Hosting) ===
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

# === Политика: даём публичный доступ на чтение файлов ===
data "aws_iam_policy_document" "public_read" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.public_read.json
}

# === Загружаем файлы сайта как объекты S3 ===

# index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"

  etag = filemd5("${path.module}/index.html")

  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website
  ]
}

# styles.css
resource "aws_s3_object" "styles" {
  bucket       = aws_s3_bucket.website.id
  key          = "styles.css"
  source       = "${path.module}/styles.css"
  content_type = "text/css"

  etag = filemd5("${path.module}/styles.css")

  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website
  ]
}

# script.js
resource "aws_s3_object" "script" {
  bucket       = aws_s3_bucket.website.id
  key          = "script.js"
  source       = "${path.module}/script.js"
  content_type = "application/javascript"

  etag = filemd5("${path.module}/script.js")

  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website
  ]
}

# === Выводим endpoint статического сайта ===
output "website_endpoint" {
  description = "URL сайта в S3 Static Website Hosting"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

