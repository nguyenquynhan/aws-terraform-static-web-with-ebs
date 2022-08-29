#!/bin/bash
sudo su
mkfs -t xfs /dev/xvdh
mkdir /home/ec2-user/data
mount /dev/xvdh /home/ec2-user/data
exit