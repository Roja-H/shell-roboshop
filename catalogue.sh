#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILES="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD  # here PWD is /home/ec2-user/shell-roboshop

mkdir -p $LOGS_FOLDER
echo "script execution started at $(date)" | tee -a $LOG_FILES

# here tee command is used to show the basic logs on screen too and store in log_files"
if [ $USERID -ne 0 ]
then
    echo -e " $R ERROR: please run this is in root user $Y " | tee -a $LOG_FILES
    exit 1 #give anything other then 0 upto 127
else
    echo -e "you are running in root user $G" | tee -a $LOG_FILES
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILES
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILES
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILES
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILES
VALIDATE $? "enabling nodejs"

dnf install nodejs -y &>>$LOG_FILES
VALIDATE $? "Installing nodejs"

id roboshop &>>$LOG_FILES
if [ $? -eq 0 ]
   then 
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   echo " creating roboshop user"
else 
    echo "roboshop user already exists....skipping"    
fi 

mkdir -p /app &>>$LOG_FILES
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloading catalogue file"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILES
VALIDATE $? "unzipping catalogue"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue file to systemctl"

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "Starting catalogue"

cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILES
VALIDATE $? "Installing MongoDB Client"

STATUS=$(mongosh --host mongodb.rojahanumantharaju.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.rojahanumantharaju.site </app/db/master-data.js &>>$LOG_FILES
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi






   
