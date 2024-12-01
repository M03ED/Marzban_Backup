# Marzban_Backup
You Can Use This Script To Make Backup From `.env` , `xray_config.json` , `docker-compose.yml` , `certificates` , `templates` And `Database` On Telegram And Discord.
- Both MySQL and SQlite3 Are Supported.

# Usage
## Step 1
First You Need To Install `tar` , `wget` And `curl`.
```bash
apt install tar curl wget
```
Then Change The Directory.
```bash
cd /opt
```
Download Project.
```bash 
git clone "https://github.com/M03ED/Marzban_Backup.git"
```
Enter Project Folder
```bash
cd /opt/Marzban_Backup
```
Make A Folder For Temporary Files (You can change this path from config.json).
```bash
mkdir temp
```

## Step 2
Set-up Your Config file.
```json
{
    "backup_dir": "/opt/Marzban_Backup/temp",
    "backup_interval_time": 60, // interval per minutes
    "telegram": {
        "bot_token": "your-telegram-bot-token", // replace with telegram bot token, max to 50mb backup
        "chat_id": "your-chat-id" // replace with your telegram id, you can find it with https://t.me/username_to_id_bot
    },
    "discord": {
        "backup_url": "your-discord-webhook-url" // replace with discord webhook, max to 10mb backup
    },
    "databases": [
        {
            "type": "mariadb", //can be mysql, sqlite or mariadb
            "env_path": "/opt/marzban/.env",
            "docker_path": "/opt/marzban/docker-compose.yml",
            "container_name": "mariadb", // database container name
            "external": [
                "/var/lib/marzban/certs",
                "/var/lib/marzban/templates",
                "/var/lib/marzban/xray_config.json"
            ] // any file or folder you need to add to backup file
        }
    ] // list of database's, you can add many as you want
}
```

## Step 3
You Should Add Execute Permissions To The Script.
```bash
chmod +x /opt/Marzban_Backup/backup.sh
```

## Step 4
Then Run The Program In `nohup` Mode To Stay Active In Background.
```bash
nohup /opt/Marzban_Backup/backup.sh &
```

- Now You Have Your Backup On Telegram And Discord.
- New File With `nohup.out` Name Gonna Be Created in `/opt/marzban` And It Will Record Your Script Log , You Can Delete It When Ever You Want.
