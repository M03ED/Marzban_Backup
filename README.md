# Marzban_Backup
You Can Use This Script To Make Backup From `.env` , `xray_config.json` , `docker-compose.yml` , `certificates` , `templates` And Database On Telegram.
- Both MySQL and SQlite3 Are Supported.

# Usage
## Step 1
First You Need To Install `tar` , `wget` And `curl`.
```bash
apt install tar curl wget
```
Then Change The Directory.
```bash
cd /opt/marzban
```
Make A Folder For Temporary Files.
```bash
mkdir backup
```
- Download The Script.
### Telegram Backup
```bash 
wget https://raw.githubusercontent.com/M03ED/Marzban_Backup/main/backup.sh
```
### Discord Backup
```bash 
wget https://raw.githubusercontent.com/M03ED/Marzban_Backup/main/backup.py
```
### Only Discord 
install these 2 library for python (use python 3.10+)
```bash 
pip install discord
pip install python-dotenv
```
## Step 2
Change Variables If Your File Name Or Location Is Diffrent.
### Telegram
```bash
ENV_PATH="/opt/marzban/.env"
DB_NAME="marzban"
CONTAINER_NAME="mysql"
BACKUP_DIR="/opt/marzban/backup"
DOCKER_PATH="/opt/marzban/docker-compose.yml"
CERTS="/var/lib/marzban/certs"
TEMPLATES="/var/lib/marzban/templates"
```
### Discord 
```python
env_path = "/opt/marzban/.env"
container_name = "mysql"
docker_path = "/opt/marzban/docker-compose.yml"
certs = "/var/lib/marzban/certs"
```
## Step 3
Set These Variables In .env File Like This.
### Telegram
```env
TELEGRAM_BACKUP_TOKEN = "11111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
TELEGRAM_ADMIN_ID = "11111111111"
BACKUP_INTERVAL_TIME =120 #backup time per minutes
```
### Discord
```env
DISCORD_BOT_TOKEN = "d5aw468w4d5aw4d65sad56egh564r4fh65y468ty2"
DISCORD_CHANNEL_ID = "16541586145651"
BACKUP_INTERVAL_TIME =120 #backup time per minutes
```
## Step 4
You Should Add Execute Permissions To The Script.
### Telegram
```bash
chmod +x /opt/marzban/backup.sh
```
### Discord
```bash
chmod +x /opt/marzban/backup.py
```
## Step 5 
Then Run The Program In `nohup` Mode To Stay Active In Background.
## Telegram
```bash
nohup /opt/marzban/backup.sh &
```
### Discord
```bash
nohup /opt/marzban/backup.sh &
```
- Now You Have Your Backup On Telegram.
- New File With `nohup.out` Gonna Be Created in `/opt/marzban` And It Will Record Your Script Log , You Can Delete It When Ever You Want.
