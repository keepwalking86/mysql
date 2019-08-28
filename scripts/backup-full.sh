#!/bin/bash
## Script for backup full database
## Create by Keepwalking86

#Set initial variables 
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASS="P@ssw0rd"
MYSQLDUMP="$(which mysqldump)"
SMTP_SERVER="mail.example.com"
SMTP_USER="notify@example.com"
SMTP_PASS="P@ssw0rd"
TO_USER="keepwalking86@example.com"

#root store directory
DEST="/backup/mysql"
[[ ! -d $DEST ]] && mkdir -p $DEST

# datetime
NOW="$(date +"%Y%m%d")"

# Create the backup directory
# mkdir -p $DEST/$NOW
 
# Remove backups older than 7 days
find $DEST -maxdepth 1 -type f -mtime +7 -exec rm -rf {} \;

#Starting time to backup
start_time=$(date)

#Begining backup
$MYSQLDUMP -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASS} \
	--all-databases | gzip > ${DEST}/all-database-${NOW}.sql.gz

# Send notify backup result
#Check status
[ $? -eq 0 ] && status="Successful Backup" || status="Failed Backup"
#require: install mailx
mailx -v -r "$SMTP_USER" -s "Notify MySQL backup" -S smtp="$SMTP_SERVER:25" -S smtp-auth=login -S smtp-auth-user="$SMTP_USER" -S smtp-auth-password="$SMTP_PASS" $TO_USER <<EOF
The backup job finished.
Start date: $start_time
End date: $(date)
Status: $status
EOF
