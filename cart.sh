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

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling Nodejs Module"

dnf module enable nodejs:20 -y &>> $LOGFILE
VALIDATE $? "Enabling Nodejs 20 Module"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing Nodejs"


id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGFILE
    VALIDATE $? "Adding Roboshop User"
else
    echo -e "Roboshop User Already Exists $Y SKIPPING... $N"
fi


mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating Application Directory"    

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $LOGFILE 
VALIDATE $? "Downloading Cart Application Content"

cd /app 
unzip -o /tmp/cart.zip &>> $LOGFILE 
VALIDATE $? "Extracting Cart Application Content" 

npm install &>> $LOGFILE
VALIDATE $? "Installing Nodejs Dependencies"

cp /home/ec2-user/roboshop-shell/cart.service /etc/systemd/system/cart.service &>> $LOGFILE
VALIDATE $? "Copying Cart Systemd Service File"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading Systemd"

systemctl enable cart &>> $LOGFILE
VALIDATE $? "Enabling Cart Service"
systemctl start cart &>> $LOGFILE
VALIDATE $? "Starting Cart Service"
