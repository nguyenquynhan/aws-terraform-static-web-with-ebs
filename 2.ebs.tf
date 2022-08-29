resource "aws_ebs_volume" "web_volume" {
  availability_zone = "ap-southeast-1a"
  type = "gp2"
  size = 1
  tags = {
    "Name" = "web_volume"
  }
}