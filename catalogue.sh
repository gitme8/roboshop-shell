
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

VALIDATE $? "Adding Roboshop User"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating Application Directory"    

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGFILE 
VALIDATE $? "Downloading Catalogue Application Content"

cd /app 
unzip -o /tmp/catalogue.zip &>> $LOGFILE 
VALIDATE $? "Extracting Catalogue Application Content" 

npm install &>> $LOGFILE
VALIDATE $? "Installing Nodejs Dependencies"

cp /home/ec2-user/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "Copying Catalogue Systemd Service File"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading Systemd"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enabling Catalogue Service" 
systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Starting Catalogue Service"

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "Copying Mongodb Repo File"
dnf install mongodb-mongosh -y &>> $LOGFILE
VALIDATE $? "Installing Mongodb Shell"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>> $LOGFILE
VALIDATE $? "Loading Catalogue Data to Mongodb"

systemctl restart catalogue &>> $LOGFILE
VALIDATE $? "Restarting Catalogue Service"