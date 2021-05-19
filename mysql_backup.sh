#!/bin/sh

RETENTION_PERIOD=$1

NOW="$(date +'%d_%m_%Y_%H_%M_%S')"
FILENAME="$MYSQL_DATABASE$NOW".gz
BACKUP_DIR="/tmp/mysql"
FULLPATH_BACKUPFILE="$BACKUP_DIR/$FILENAME"
LOG_FILENAME="$MYSQL_DATABASE"_log_"$(date +'%Y_%m_%d')".txt
LOG_FILE="$BACKUP_DIR/$LOG_FILENAME"

mkdir -p $BACKUP_DIR
echo "mysqldump started at $(date +'%d-%m-%Y %H:%M:%S')" >> "$LOG_FILE"
mysqldump -h $MYSQL_HOST --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD $MYSQL_DATABASE | gzip > "$FULLPATH_BACKUPFILE"
echo "mysqldump finished at $(date +'%d-%m-%Y %H:%M:%S')" >> "$LOG_FILE"
ls -lah $BACKUP_DIR

aws s3 cp --endpoint-url=$STORAGE_ENDPOINT --region $STORAGE_REGION $FULLPATH_BACKUPFILE s3://$STORAGE_BUCKET/mysql/$FILENAME

# TO-DO retention
# 
# echo "old files deleted" >> "$LOG_FILE"

echo "operation finished at $(date +'%d-%m-%Y %H:%M:%S')" >> "$LOG_FILE"
echo "*****************" >> "$LOG_FILE"

cat $LOG_FILE
aws s3 cp --endpoint-url=$STORAGE_ENDPOINT --region $STORAGE_REGION $LOG_FILE s3://$STORAGE_BUCKET/mysql/$LOG_FILENAME

exit 0
