#!/usr/bin/env bash

id
whoami

mount -t cifs -o username=your_smb_user,password=password,uid=$(id -u),gid=$(id -g) //192.168.1.50/SharedFolder /mnt/my_share
