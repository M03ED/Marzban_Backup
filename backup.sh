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

SQLALCHEMY_DATABASE_URL=$(get_env_var 'SQLALCHEMY_DATABASE_URL')
XRAY_CONFIG=$(get_env_var 'XRAY_JSON')
BOT_TOKEN=$(get_env_var 'TELEGRAM_BACKUP_TOKEN')
CHAT_ID=$(get_env_var 'TELEGRAM_ADMIN_ID')
BACKUP_INTERVAL_TIME=$(get_env_var 'BACKUP_INTERVAL_TIME')

# Calculate sleep time in seconds
SLEEP_TIME=$((BACKUP_INTERVAL_TIME * 60))

# Log function for better visibility
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1"
}

# Function to send a file to Telegram
send_backup_to_telegram() {
    local file_path="$1"
    curl -F chat_id="$CHAT_ID" -F document=@"$file_path" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
}

# Backup function for SQLite
backup_sqlite() {
    log "Starting SQLite backup..."

    FILE_NAME="$DB_NAME-$(date '+%Y-%m-%d_%H:%M').tar.gz"

    # Backup SQLite database file
    cp "$SQLALCHEMY_DATABASE_URL" "$BACKUP_DIR/$DB_NAME.sqlite3"

    # Create a tar archive with all backup files, including the directories
    tar czvf "$BACKUP_DIR/$FILE_NAME" "$BACKUP_DIR/$DB_NAME.sqlite3" "$ENV_PATH" "$DOCKER_PATH" "$CERTS" "$TEMPLATES"

    # Send backup to Telegram bot
    send_backup_to_telegram "$BACKUP_DIR/$FILE_NAME"

    # Cleanup
    rm "$BACKUP_DIR/$DB_NAME.sqlite3"
    rm "$BACKUP_DIR/$FILE_NAME"

    log "SQLite backup completed!"
}

# Backup function for MySQL
backup_mysql() {
    log "Starting MySQL backup..."

    FILE_NAME="$DB_NAME-$(date '+%Y-%m-%d_%H:%M').tar.gz"

    # Create MySQL database backup
    docker compose -f "$DOCKER_PATH" exec "$CONTAINER_NAME" mysqldump -u root -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/db_backup.sql"

    # Create tar archive with all backup files, including the directories
    tar czvf "$BACKUP_DIR/$FILE_NAME" db_backup.sql "$ENV_PATH" "$DOCKER_PATH" "$CERTS" "$TEMPLATES"

    # Send backup to Telegram bot
    send_backup_to_telegram "$BACKUP_DIR/$FILE_NAME"
    rm "$BACKUP_DIR/$FILE_NAME"

    log "MySQL backup completed!"
}

# Main loop
while true; do
    if [[ $SQLALCHEMY_DATABASE_URL == sqlite* ]]; then
        backup_sqlite
    else
        DB_PASSWORD=$(get_env_var 'MYSQL_ROOT_PASSWORD')
        backup_mysql
    fi

    log "Sleeping for $SLEEP_TIME seconds..."
    sleep "$SLEEP_TIME"
done
