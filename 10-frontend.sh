#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USERID -ne 0 ]; then
 echo -e "$TIMESTAMP [ERROR] $R please run the script with root access $N" | tee -a $LOGS_FILE
 exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
     echo -e "$TIMESTAMP [ERROR] $R Failure $N" | tee -a $LOGS_FILE
     exit 1
    else 
     echo -e "$TIMESTAMP [INFO] $G Success $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx -y &>> LOGS_FILE
dnf module enable nginx:1.24 -y &>> LOGS_FILE
dnf install nginx -y &>> LOGS_FILE
VALIDATE $? "installing nginx"

rm -rf /usr/share/nginx/html/*  &>> LOGS_FILE
VALIDATE $? "Removed Default code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>> LOGS_FILE
VALIDATE $? "Downloaded and extracted frontend code"

rm -rf /etc/nginx/nginx.conf
VALIDATE $? "Removed Default conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied roboshop nginx conf"

systemctl enable nginx 
systemctl start nginx &>> LOGS_FILE
VALIDATE $? "Enabled and restarted nginx"
