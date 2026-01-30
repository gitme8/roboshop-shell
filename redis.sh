#!/bin/bash

ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

MONGODB_HOST="mongodb.sai-ops.online"

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"
exec &> $LOGFILE

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

dnf module disable redis -y &>> $LOGFILE
VALIDATE $? "Disabling Redis Module"
dnf module enable redis:7 -y &>> $LOGFILE
VALIDATE $? "Enabling Redis 7 Module"
dnf install redis -y &>> $LOGFILE
VALIDATE $? "Installing Redis"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>> $LOGFILE
VALIDATE $? "Updating Redis Configuration File" 

sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf &>> $LOGFILE
VALIDATE $? "Disabling Protected Mode in Redis Configuration File"


systemctl enable redis &>> $LOGFILE
VALIDATE $? "Enabling Redis Service"
systemctl start redis &>> $LOGFILE
VALIDATE $? "Starting Redis Service"
