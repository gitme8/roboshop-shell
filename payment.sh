#!/bin/bash

ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"
SCRIPT_DIR=$PWD

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

dnf install python3 gcc python3-devel -y &>> $LOGFILE
VALIDATE $? "Installing Python3 and Build Tools"

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

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> $LOGFILE 
VALIDATE $? "Downloading Payment Application Content"

cd /app 

rm -rf /app/* &>> $LOGFILE
VALIDATE $? "Cleaning Application Directory"

unzip -o /tmp/payment.zip &>> $LOGFILE 
VALIDATE $? "Extracting Payment Application Content"


pip3 install -r requirements.txt &>> $LOGFILE
VALIDATE $? "Installing Python Dependencies"

mv /etc/systemd/system/payment.service /etc/systemd/system/payment.service.bak &>> $LOGFILE
VALIDATE $? "Backing up Existing Payment Systemd File"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> $LOGFILE
VALIDATE $? "Copying Payment Systemd Service File"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading Systemd Services"    

systemctl enable payment &>> $LOGFILE
systemctl start payment &>> $LOGFILE
VALIDATE $? "Enabling and Starting Payment Service"

