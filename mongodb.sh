#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILES="$LOGS_FOLDER/$SCRIPT_NAME.log"

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
        echo  -e " $G INSTALLING $2 SUCCESS " &>>$LOG_FILES
    else
        echo -e "INSTALLING $2 is failure $R" &>>$LOG_FILES
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongodb.repo 
VALIDATE $? "Copying Mongo Repo"

dnf install mongodb-org -y &>>$LOG_FILES
VALIDATE $? "Installing mongodb"

systemctl enable mongod &>>$LOG_FILES
VALIDATE $? "Enabled mongodb"

systemctl start mongod &>>$LOG_FILES
VALIDATE $? "Started mongodb"

sed -i "s/127.0.0.1/ 0.0.0.0" /etc/mongod.conf &>>$LOG_FILES
VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILES
VALIDATE $? "restarting mongod"