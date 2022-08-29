resource "null_resource" "remote" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("key.pem")
    host        = aws_instance.web_ebs.public_ip
  }

  #Copy folder web_app vào thư mục /home/ec2-user/
  provisioner "file" {
    source      = "./web_app"
    destination = "/home/ec2-user"
  }

  # Setup sourcode and re-config nginx
  provisioner "remote-exec" {
    script = "./remote-exec.bash"
  }
}
