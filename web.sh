#!/bin/bash

ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

MONGODB_HOST="mongodb.sai-ops.online"

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"

echo "script stareted executing at $TIMESTAMP" &>> $LOGFILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "ERROR:: $2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1 # you can give other than 0
else
    echo "You are root user"
fi # fi means reverse of if, indicating condition end

dnf module disable nginx -y &>> $LOGFILE
VALIDATE $? "Disabling Nginx Module"

dnf module enable nginx:1.24 -y &>> $LOGFILE
VALIDATE $? "Enabling Nginx 1.24 Module"

dnf install nginx -y &>> $LOGFILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $LOGFILE
VALIDATE $? "Enabling Nginx Service"    

systemctl start nginx &>> $LOGFILE
VALIDATE $? "Starting Nginx Service"

rm -rf /usr/share/nginx/html/* &>> $LOGFILE
VALIDATE $? "Removing Default Nginx Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOGFILE
VALIDATE $? "Downloading Frontend Content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>> $LOGFILE
VALIDATE $? "Extracting Frontend Content"

cp /home/ec2-user/roboshop-shell/nginx.conf /etc/nginx/nginx.conf &>> $LOGFILE
VALIDATE $? "Copying Nginx Roboshop Configuration File" 

systemctl restart nginx &>> $LOGFILE
VALIDATE $? "Restarting Nginx Service"

