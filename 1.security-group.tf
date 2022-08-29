resource "aws_security_group" "allow_port_80" {
  name = "allow_port_80"
  description = "Open port 80"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow http access anywhere with port 80"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow SSH from anywhere"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description = "Allow traffic out"
  }

  tags = {
    "Name" = "allow_port_80"
  }
}