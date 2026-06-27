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

dnf module disable nodejs -y &>> LOGS_FILE
VALIDATE $? "disable nodejs server"

dnf module enable nodejs:20 -y &>> LOGS_FILE
VALIDATE $? "enable nodejs server"

dnf install nodejs -y &>> LOGS_FILE
VALIDATE $? "Installing Nodejs:20 server"

id roboshop &>> LOGS_FILE
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
 VALIDATE $? "creating roboshop system user"
else
 echo -e "system user roboshop already created......$Y Skipping $N"
fi

rm -rf /app
VALIDATE $? "removing existing code"

rm -rf /tmp/catalogue.zip
VALIDATE $? "removed catalogue.zip"

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
cd /app 
unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Downloaded and extracted catalogue code"

npm install &>>$LOGS_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Added Mongo repo" 

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installed MongoDB client"

##checking the index
INDEX=$(mongosh --host mongodb.daws-90s.sbs --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.daws-90s.sbs </app/db/master-data.js &>>$LOGS_FILE
    VALIDATE $? "Load Products"
else
   echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl enable catalogue &>>$LOGS_FILE
systemctl restart catalogue &>>$LOGS_FILE
VALIDATE $? "Restarting catalogue"