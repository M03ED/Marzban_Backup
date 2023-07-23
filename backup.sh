#!/bin/bash

ENV_PATH="/opt/marzban/.env"
DB_NAME="marzban"
CONTAINER_NAME="mysql"
BACKUP_DIR="/opt/marzban/backup"
DOCKER_PATH="/opt/marzban/docker-compose.yml"
FILE_NAME="$DB_NAME-$(date '+%Y-%m-%d_%H:%M').tar.gz"
XRAY_CONFIG=$(grep 'XRAY_JSON' $ENV_PATH | cut -d '=' -f2 | tr -d '"')
DB_PASSWORD=$(grep 'MYSQL_ROOT_PASSWORD' $ENV_PATH | cut -d '=' -f2 | tr -d '"')
BOT_TOKEN=$(grep 'TELEGRAM_BACKUP_TOKEN' $ENV_PATH | cut -d '=' -f2 | tr -d '"')
CHAT_ID=$(grep 'TELEGRAM_ADMIN_ID' $ENV_PATH | cut -d '=' -f2 | tr -d '"')
BACKUP_INTERVAL_TIME=$(grep 'BACKUP_INTERVAL_TIME' $ENV_PATH | cut -d '=' -f2)

# Calculate sleep time in seconds
SLEEP_TIME=$((BACKUP_INTERVAL_TIME * 60))

# Run backup in a loop
while true; do

    # Create database backup
    docker compose -f /opt/marzban/docker-compose.yml exec $CONTAINER_NAME mysqldump -u root -p$DB_PASSWORD $DB_NAME > db_backup.sql

    # Create tar archive with all backup files
    tar czvf $BACKUP_DIR/$FILE_NAME db_backup.sql $ENV_PATH $DOCKER_PATH $XRAY_CONFIG

    # Send backup to Telegram bot
    curl -F chat_id=$CHAT_ID -F document=@"$BACKUP_DIR/$FILE_NAME" https://api.telegram.org/bot$BOT_TOKEN/sendDocument

    # Delete backup files
    rm db_backup.sql
    rm $BACKUP_DIR/$FILE_NAME

    # Sleep for specified interval
    sleep $SLEEP_TIME
done