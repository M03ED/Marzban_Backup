#!/bin/bash

CONFIG_FILE="config.json"

get_config() {
    jq -r "$1 // \"\"" "$CONFIG_FILE"
}

get_env_var() {
    local env_file="$1"
    shift
    
    if [[ ! -f "$env_file" ]]; then
        echo "Error: Environment file '$env_file' not found." >&2
        return 1
    fi

    while [[ $# -gt 0 ]]; do
        local var_name="$1"
        
        local var_value=$(grep -E "^$var_name\s*=" "$env_file" | sed -E 's/^[^=]*=\s*//; s/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//')
        
        if [[ -n "$var_value" ]]; then
            DB_URL="$var_value"
            return 0
        fi
        
        shift 
    done
    
    echo "Error: No non-empty variable found in the environment file." >&2
    DB_URL=""
    return 1
}

# Global configurations
BACKUP_DIR=$(get_config '.backup_dir')
BACKUP_INTERVAL_TIME=$(get_config '.backup_interval_time')
BOT_TOKEN=$(get_config '.telegram.bot_token')
CHAT_ID=$(get_config '.telegram.chat_id')
DISCORD_BACKUP_URL=$(get_config '.discord.backup_url')

SLEEP_TIME=$((BACKUP_INTERVAL_TIME * 60))

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1"
}

send_backup_to_telegram() {
    local file_path="$1"
    curl -F chat_id="$CHAT_ID" -F document=@"$file_path" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
}

send_backup_to_discord() {
    local file_path="$1"
    local message="Here is your backup"

    echo
    echo "Sending Backup To Discord"
    curl -X POST -H "Content-Type: multipart/form-data" -F "content=$messege" -F "file=@$file_path" $DISCORD_BACKUP_URL
}

backup_sqlite() {
    local backup_name=$1
    local db_path=$2
    shift

    local additional_files=("$@")

    log "Starting SQLite backup for $backup_name..."

    FILE_NAME="$backup_name-$(date '+%Y-%m-%d_%H:%M').tar.gz"

    cp "$db_path" "$BACKUP_DIR/$backup_name.sqlite3"
    tar czvf "$BACKUP_DIR/$FILE_NAME" "$BACKUP_DIR/$backup_name.sqlite3" "${additional_files[@]}"

    send_backup_to_telegram "$BACKUP_DIR/$FILE_NAME"
    send_backup_to_discord "$BACKUP_DIR/$FILE_NAME"

    rm "$BACKUP_DIR/$backup_name.sqlite3"
    rm "$BACKUP_DIR/$FILE_NAME"

    log "SQLite backup for $db_name completed!"
}

backup_mysql() {
    local db_name=$1
    local backup_name=$2
    local container_name=$3
    local docker_path=$4
    local user=$5
    local password=$6
    shift
    local additional_files=("$@")
    
    log "Starting MySQL backup for $db_name..."
    FILE_NAME="$backup_name-$(date '+%Y-%m-%d_%H:%M').tar.gz"
    
    if ! output=$(docker compose -f "$docker_path" exec "$container_name" mysqldump -u root -p"$password" "$db_name" 2>&1 > "$BACKUP_DIR/db_backup.sql"); then
        if [[ "$output" == *"Enter password:"* || "$output" == *"Access denied"* ]]; then
            log "Error: Authentication failed for MySQL backup. Please check credentials."
            return 1
        else
            log "Error during MySQL backup: $output"
            return 1
        fi
    fi
    
    tar czvf "$BACKUP_DIR/$FILE_NAME" "$BACKUP_DIR/db_backup.sql" "$docker_path" "${additional_files[@]}"
    send_backup_to_telegram "$BACKUP_DIR/$FILE_NAME"
    send_backup_to_discord "$BACKUP_DIR/$FILE_NAME"
    
    rm "$BACKUP_DIR/db_backup.sql"
    rm "$BACKUP_DIR/$FILE_NAME"
    
    log "MySQL backup for $db_name completed!"
    return 0
}

backup_mariadb() {
    local db_name=$1
    local backup_name=$2
    local container_name=$3
    local docker_path=$4
    local user=$5
    local password=$6
    shift
    local additional_files=("$@")
    
    log "Starting MariaDB backup for $db_name..."
    FILE_NAME="$backup_name-$(date '+%Y-%m-%d_%H:%M').tar.gz"
    
    if ! output=$(docker compose -f "$docker_path" exec "$container_name" mariadb-dump -u"$user" -p"$password" "$db_name" 2>&1 > "$BACKUP_DIR/db_backup.sql"); then
        if [[ "$output" == *"Enter password:"* || "$output" == *"Access denied"* ]]; then
            log "Error: Authentication failed for MariaDB backup. Please check credentials."
            return 1
        else
            log "Error during MariaDB backup: $output"
            return 1
        fi
    fi
    
    tar czvf "$BACKUP_DIR/$FILE_NAME" "$BACKUP_DIR/db_backup.sql" "$env_path" "$docker_path" "${additional_files[@]}"
    send_backup_to_telegram "$BACKUP_DIR/$FILE_NAME"
    send_backup_to_discord "$BACKUP_DIR/$FILE_NAME"
    
    rm "$BACKUP_DIR/db_backup.sql"
    rm "$BACKUP_DIR/$FILE_NAME"
    
    log "MariaDB backup for $db_name completed!"
    return 0
}


parse_sqlalchemy_url() {
    local input_string="$1"
    
    local credentials=$(echo "$input_string" | sed -n 's/.*mysql:\/\/\(.*\)@.*/\1/p')
    
    local username=$(echo "$credentials" | cut -d ':' -f 1)
    local pass=$(echo "$credentials" | cut -d ':' -f 2)
    local db=$(echo "$input_string" | sed -n 's/.*\/\([^/]*\)$/\1/p')

    user="$username"
    password="$pass"
    database="$db"
}

parse_gorm_url() {
    local input_string="$1"

    local username=$(echo "$input_string" | cut -d ':' -f 1)
    
    local username=$(echo "$input_string" | sed -n 's/^\([^:]*\):.*@tcp.*/\1/p')
    local pass=$(echo "$input_string" | sed -n 's/^[^:]*:\([^@]*\)@tcp.*/\1/p')
    local db=$(echo "$input_string" | sed -n 's/.*\/\([^?]*\).*/\1/p' | cut -d '?' -f 1)
    db=$(echo "$db" | cut -d '?' -f 1)
    
    user="$username"
    password="$pass"
    database="$db"
}


process_database() {
    local index=$1

    local DB_NAME=$(get_config ".databases[$index].db_name")
    local DB_TYPE=$(get_config ".databases[$index].type")
    local ENV_PATH=$(get_config ".databases[$index].env_path")
    local CONTAINER_NAME=$(get_config ".databases[$index].container_name")
    local DOCKER_PATH=$(get_config ".databases[$index].docker_path")
    local URL_FORMAT=$(get_config ".databases[$index].url_format")

    get_env_var $ENV_PATH "DATABASE_URL" "SQLALCHEMY_DATABASE_URL"
    local EXTERNAL_PATHS=$(jq -r ".databases[$index].external | join(\" \")" "$CONFIG_FILE")

    if [[ $DB_TYPE == "sqlite" ]]; then
        DB_URL="${DB_URL#sqlite:///}"
    else
        parse_sqlalchemy_url "$DB_URL"
    fi

    if [[ $DB_TYPE == "sqlite" ]]; then
        DB_URL="${DB_URL#sqlite:///}"
    else
        case $URL_FORMAT in
            "sqlalchemy")
                parse_sqlalchemy_url "$DB_URL"
                ;;
            "gorm")
                parse_gorm_url "$DB_URL"
                ;;
            *)
                log "Unsupported database type: $DB_TYPE"
                ;;
        esac
    fi
    
    if [[ -z "$DB_NAME" ]]; then
        DB_NAME="$database"
    fi

    case $DB_TYPE in
        "sqlite")
            backup_sqlite "$DB_NAME" "$SQLALCHEMY_DATABASE_URL" "$ENV_PATH" "$DOCKER_PATH" $EXTERNAL_PATHS
            ;;
        "mysql")
            backup_mysql "$database" "$DB_NAME" "$CONTAINER_NAME" "$DOCKER_PATH" "$user" "$password" "$ENV_PATH" $EXTERNAL_PATHS
            ;;
        "mariadb")
            backup_mariadb "$database" "$DB_NAME" "$CONTAINER_NAME" "$DOCKER_PATH" "$user" "$password" "$ENV_PATH" $EXTERNAL_PATHS
            ;;
        *)
            log "Unsupported database type: $DB_TYPE"
            ;;
    esac
}

# Main loop
while true; do
    DATABASE_COUNT=$(jq '.databases | length' "$CONFIG_FILE")

    for ((i = 0; i < DATABASE_COUNT; i++)); do
        process_database "$i"
    done

    log "Sleeping for $SLEEP_TIME seconds..."
    sleep "$SLEEP_TIME"
done