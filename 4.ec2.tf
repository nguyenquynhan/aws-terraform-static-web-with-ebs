resource "aws_instance" "web_ebs" {
  ami = "ami-0b89f7b3f054b957e"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1a"
  vpc_security_group_ids = [ aws_security_group.allow_port_80.id ]
  key_name = "techmaster-03-ec2-public" # Chú ý: đổi lại keyname của bạn
  user_data              = file("ec2-userdata.bash")
  tags = {
    "Name" = "web_ebs"
  }
}