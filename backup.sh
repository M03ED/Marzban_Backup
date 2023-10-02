#!/bin/bash

ENV_PATH="/opt/marzban/.env"
DB_NAME="marzban"
CONTAINER_NAME="mysql"
BACKUP_DIR="/opt/marzban/backup"
DOCKER_PATH="/opt/marzban/docker-compose.yml"
CERTS="/var/lib/marzban/certs"
TEMPLATES="/var/lib/marzban/templates"

# Extract environment variables
get_env_var() {
    grep "$1" "$ENV_PATH" | cut -d '=' -f2 | tr -d '"'
}

XRAY_CONFIG=$(grep 'XRAY_JSON' $ENV_PATH | cut -d '=' -f2 | tr -d '"')
DB_PASSWORD=$(get_env_var 'MYSQL_ROOT_PASSWORD')
BOT_TOKEN=$(get_env_var 'TELEGRAM_BACKUP_TOKEN')
CHAT_ID=$(get_env_var 'TELEGRAM_ADMIN_ID')
BACKUP_INTERVAL_TIME=$(grep 'BACKUP_INTERVAL_TIME' $ENV_PATH | cut -d '=' -f2)

# Calculate sleep time in seconds
SLEEP_TIME=$((BACKUP_INTERVAL_TIME * 60))

# Log function for better visibility
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1"
}

# Backup function
perform_backup() {
    log "Starting backup..."

    FILE_NAME="$DB_NAME-$(date '+%Y-%m-%d_%H:%M').tar.gz"

    # Create database backup
    docker compose -f "$DOCKER_PATH" exec "$CONTAINER_NAME" mysqldump -u root -p"$DB_PASSWORD" "$DB_NAME" > db_backup.sql

    # Create tar archive with all backup files, including the directories
    tar czvf "$BACKUP_DIR/$FILE_NAME" db_backup.sql "$ENV_PATH" "$DOCKER_PATH" "$CERTS" "$TEMPLATES"

    # Send backup to Telegram bot
    curl -F chat_id="$CHAT_ID" -F document=@"$BACKUP_DIR/$FILE_NAME" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

    # Cleanup
    rm db_backup.sql
    rm "$BACKUP_DIR/$FILE_NAME"

    log "Backup completed!"
}

# Main loop
while true; do
    perform_backup
    log "Sleeping for $SLEEP_TIME seconds..."
    sleep "$SLEEP_TIME"
done