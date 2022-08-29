sudo amazon-linux-extras install nginx1 -y
sudo mv /home/ec2-user/web_app /home/ec2-user/data/web_app
sudo sed -i s+/usr/share/nginx/html+/home/ec2-user/data/web_app+g /etc/nginx/nginx.conf
sudo chmod o+x /home/ec2-user
sudo systemctl restart nginx.service