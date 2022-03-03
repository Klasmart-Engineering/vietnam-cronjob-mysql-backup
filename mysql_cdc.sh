#!/bin/sh
#
# Arguments (set as environment variables)
# - MYSQL_HOST
# - MYSQL_USERNAME
# - MYSQL_PASSWORD
# - MYSQL_DATABASE
# - STORAGE_ENDPOINT
# - STORAGE_REGION
# - STORAGE_BUCKET
# - DATABASE
#
# Example:
#
#     export MYSQL_HOST="10.0.2.8"
#     export MYSQL_USERNAME="username"
#     export MYSQL_PASSWORD="password"
#     export MYSQL_DATABASE="kidsloop2"
#     export STORAGE_ENDPOINT="s3_endpoint_url"
#     export STORAGE_REGION="kl"
#     export STORAGE_BUCKET="kl-data-vn-prod-sg"
#     export DATABASE="cms"
#     mysql_cdc.sh
#

NOW="$(date +'%Y_%m_%d_%H_%M_%S')"
FILENAME="$MYSQL_DATABASE$NOW".csv
BACKUP_DIR="/tmp/mysql_csv"
FULLPATH_BACKUPFILE="$BACKUP_DIR/$FILENAME"
LOG_FILENAME="$MYSQL_DATABASE"_log_"$(date +'%Y_%m_%d')".log
LOG_FILE="$BACKUP_DIR/$LOG_FILENAME"
S3_PATH="s3://$STORAGE_BUCKET/datalake/rdbs/$DATABASE/$MYSQL_DATABASE/"

mkdir -p $BACKUP_DIR
echo "$0 started at $(date +'%d-%m-%Y %H:%M:%S')" >> "$LOG_FILE"

# create a file and sets up column names using the information_schema
mysql -h "$MYSQL_HOST" --user="$MYSQL_USERNAME" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE" -B -e \
  "SELECT COLUMN_NAME FROM information_schema.COLUMNS C WHERE table_name = '$TABLE';" \
  | awk '{print $1}' \
  | grep -iv ^COLUMN_NAME$ \
  | sed 's/^/"/g;s/$/"/g' \
  | tr '\n' ',' \
  > "$FULLPATH_BACKUPFILE"
# append newline to mark beginning of data vs. column titles
echo "" >> "$FULLPATH_BACKUPFILE"
# create a new empty data file
DATA_FILE=$(mktemp)
# dump data from DB into $DATA_FILE
mysql -h "$MYSQL_HOST" --user="$MYSQL_USERNAME" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE" -B -e \
  "SELECT * INTO OUTFILE '$DATA_FILE' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' FROM $TABLE;"
# merges data file and file w/ column names
cat "$DATA_FILE" >> "$FULLPATH_BACKUPFILE"

echo "$0 finished at $(date +'%d-%m-%Y %H:%M:%S')" >> "$LOG_FILE"

aws s3 cp --endpoint-url="$STORAGE_ENDPOINT" --region "$STORAGE_REGION" "$FULLPATH_BACKUPFILE" "$S3_PATH"
