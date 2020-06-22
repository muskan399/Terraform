resource "aws_s3_bucket" "b1" {
  bucket = "terra-new"

  tags = {
    Name = "terra-new"
  }
region ="ap-south-1"

}

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_s3_bucket_object" "object" {
  bucket = "terra-new"
  key    = "blog.jpg"
  source = "C:/Users/muska/Desktop/blogpng.png"
  acl    = "public-read"
  content_type ="image/jpg"

}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = "${aws_s3_bucket.b1.id}"

  block_public_acls   = false
  block_public_policy = false
}
