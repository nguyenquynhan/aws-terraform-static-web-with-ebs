# aws-terraform-static-web-with-ebs
Sử dụng Terraform để tạo một EC2 và một EBS, sau đó attach EBS vào EC2, triển khai một static web trên con EC2 này nhưng source phải lưu trên EBS

Tiếp tục với loạt bài về Terraform, trong bài viết này chúng ta chúng ta sẽ xây dựng một Website được host trên một con EC2. EC2 này có gắn một EBS để lưu trữ source code của Website. Hệ thống như hình bên dưới:
![image](https://user-images.githubusercontent.com/8075534/187150421-05fe8b87-1e53-4e8d-ac92-1cb66274ba3a.png)


##### Yêu cầu:
* EC2 type t2.micro
* EBS dung lượng 1G, gp2 gắn vào EC2 instance
* Triển khai bất kỳ một web site nào trong site này https://www.free-css.com/free-css-templates ở cổng 80
* Chú ý toàn bộ dữ liệu web site phải được lưu ở EBS tạo mới
* Sử dụng Nginx làm web server

##### Tiến hành viết code Terraform để triển khai
1. Tạo một Security Group cho EC2, Security Group cho phép HTTP request với port 80, đồng thời cho phép SSH từ máy local của chúng ta khi cần thiết.
   ```javascript
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
   ```
2. Tạo một Elastic Block Stograte(EBS), có type là gp2 và dung lượng 1GB
   ```javascript
   resource "aws_ebs_volume" "web_volume" {
     availability_zone = "ap-southeast-1a"
     type = "gp2"
     size = 1
     tags = {
       "Name" = "web_volume"
     }
   }
   ```
3. Tạo một EC2, trong đó:
   * availability_zone cùng với availability_zone của EBS
   * Gắn Security Group đã tạo ở bước 1 vào EC2
   * userdata là một đoạn bash script để format EBS và mount ổ đĩa vào EC2.
   ```javascript
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
   ```
   * `ec2-userdata.bash`: Bash script này được gắn vào userdata của EC2 ở trên:
      * mkfs -t xfs /dev/xvdh: lệnh này để format ổ đĩa cái đã tạo ở bước 2 và được gắn vào EC2
      * mkdir /home/ec2-user/data: tạo một thư mục data
      * mount /dev/xvdh /home/ec2-user/data: mount ở đĩa vào thư mục data vừa tạo
      ```bash
      #!/bin/bash
      sudo su
      mkfs -t xfs /dev/xvdh
      mkdir /home/ec2-user/data
      mount /dev/xvdh /home/ec2-user/data
      exit
      ```
4. Tạo một Volume Attachment, cái gắn EBS được tạo ở bước 2 vào con EC2 được tạo ở bước 3.
   ```javascript
   resource "aws_volume_attachment" "web_volume_att" {
     device_name = "/dev/xvdh"
     volume_id   = aws_ebs_volume.web_volume.id
     instance_id = aws_instance.web_ebs.id
   }
   ```
5. Tiếp đến, chúng ta tạo code để copy source của Website lên EC2. Sau đó sẽ chạy một đoạn bash script bằng remote-exec để:
   * cài đặt Nginx
   * copy source code vào /data folder
   * đổi lại root path của Nginx
   * Restart lại Nginx
   ```javascript
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
   
     #Setup sourcode and re-config nginx
     provisioner "remote-exec" {
       script = "./remote-exec.bash"
     }
   }
   ```
   * `remote-exec.bash`     
     ```bash
      sudo amazon-linux-extras install nginx1 -y
      sudo mv /home/ec2-user/web_app /home/ec2-user/data/web_app
      sudo sed -i s+/usr/share/nginx/html+/home/ec2-user/data/web_app+g /etc/nginx/nginx.conf
      sudo chmod o+x /home/ec2-user
      sudo systemctl restart nginx.service      
      ```
        * `sudo amazon-linux-extras install nginx1 -y`: cài đặt Nginx
        * `sudo mv /home/ec2-user/web_app /home/ec2-user/data/web_app`: copy source website từ thử mục `/home/ec2-user/web_app` đến thư mục `/home/ec2-user/data/web_app` bởi vì thư mục `/home/ec2-user/data` là thư mục được mount vào EBS và chúng ta muốn lưu trữ source trong EBS như đã đề cập đầu bài viết.
        * `sudo sed -i s+/usr/share/nginx/html+/home/ec2-user/data/web_app+g /etc/nginx/nginx.conf`: cập nhật lại root path của Nginx từ `/usr/share/nginx/html` thành `/home/ec2-user/data/web_app`
        * `sudo chmod o+x /home/ec2-user`: gắn quyền cho nhưng users khác có quyền thao tác trên thư mục owner của users khác, điều đó có nghĩa Nginx sẽ có quyền truy cập vào source để trong folder này.
6. Tạo code output để lấy public IP của EC2
   ```javascript
   output "public_ip" {
     description = "Public instance IP"
     value       = aws_instance.web_ebs.*.public_ip
   }
   ```

##### Các bước tạo Terraform code đã xong, bây giờ chúng ta tiến hành chạy code để triển trai hệ thống lên AWS.
```bash
terraform init
terraform validate
terraform apply -auto-approve
```
Output sẽ trả về Public IP
![image](https://user-images.githubusercontent.com/8075534/187150498-3490d569-5d71-4869-8b20-24c78303f479.png)
Chúng ta sử dụng IP đó và truy cập vào Website mà chúng ta đã host.
![image](https://user-images.githubusercontent.com/8075534/187150527-5257bf33-159f-4f6d-9a62-1eefd67c7529.png)



##### Như vậy chúng ta đã hoàn thành bài lab xây dựng một Website được host trên một con EC2 và sử dụng EBS lưu trữ source code.
