#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

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

dnf install mysql-server -y &>> LOGS_FILE
VALIDATE $? "Installing Mysql server"

systemctl enable mysqld &>> LOGS_FILE
systemctl start mysqld &>> LOGS_FILE
VALIDATE $? "enable and start Mysql server"

mysql_secure_installation --set-root-pass RoboShop@1 &>> LOGS_FILE
VALIDATE $? "setting up root password"