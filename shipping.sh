#!/bin/bash

ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


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

dnf install maven -y &>> $LOGFILE   
VALIDATE $? "Installing Maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGFILE 
VALIDATE $? "Downloading Shipping Application Content"

cd /app 
unzip -o /tmp/shipping.zip &>> $LOGFILE 
VALIDATE $? "Extracting Shipping Application Content" 

mvn clean package &>> $LOGFILE
VALIDATE $? "Building Shipping Application" 
mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "Renaming Shipping Application Jar File"

cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "Copying Shipping Systemd Service File"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading Systemd Services"

systemctl enable shipping &>> $LOGFILE
VALIDATE $? "Enabling Shipping Service"
systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting Shipping Service"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing Mysql Client"

mysql -h mysql.sai-ops.online -uroot -pRoboShop@1 < /app/schema/shipping.sql &>> $LOGFILE
VALIDATE $? "Loading Shipping Schema to Mysql Database"

mysql -h mysql.sai-ops.online -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOGFILE
VALIDATE $? "Creating Application Database User"

mysql -h mysql.sai-ops.online -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOGFILE
VALIDATE $? "Loading Master Data to Shipping Database"

systemctl restart shipping &>> $LOGFILE
VALIDATE $? "Restarting Shipping Service"
