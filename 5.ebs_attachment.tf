resource "aws_volume_attachment" "web_volume_att" {
  device_name = "/dev/xvdh"
  volume_id   = aws_ebs_volume.web_volume.id
  instance_id = aws_instance.web_ebs.id
}