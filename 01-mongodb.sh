#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
 echo "please run the script with root access" | tee -a $LOGS_FOLDER
 exit 1
fi
