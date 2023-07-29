# Marzban_Backup
You Can Use This Script To Make Backup From `.env` , `xray_config.json` , `docker-compose.yml` And MySQL Database On Telegram.
## Usage
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
Download The Script.
```bash 
wget https://raw.githubusercontent.com/M03ED/Marzban_Backup/main/backup.sh
```
Change Variables If Your File Name Or Location Is Diffrent.
```bash
ENV_PATH="/opt/marzban/.env"
DB_NAME="marzban"
CONTAINER_NAME="mysql"
BACKUP_DIR="/opt/marzban/backup"
DOCKER_PATH="/opt/marzban/docker-compose.yml"
```
Set These Variables In .env File Like This.
```env
TELEGRAM_BACKUP_TOKEN = "11111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
TELEGRAM_ADMIN_ID = "11111111111"
BACKUP_INTERVAL_TIME =120 #backup time per minutes
```
You Should Add Execute Permissions To The Script.
```bash
chmod +x /opt/marzban/backup.sh
```
Then Run The Program In `nohup` Mode To Stay Active In Background.
```bash
nohup /opt/marzban/backup.sh &
```
- Now You Have Your Backup On Telegram.
- New File With `nohup.out` Gonna Be Created in `/opt/marzban` And It Will Record Your Script Log , You Can Delete It When Ever You Want.
