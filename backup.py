import discord
from discord.ext import commands
import subprocess
import os
import time
import asyncio
from dotenv import load_dotenv

env_path = "/opt/marzban/.env"

backup_dir = '/opt/marzban/backup'
db_name = "marzban"

container_name = "mysql"
docker_path = "/opt/marzban/docker-compose.yml"
certs = "/var/lib/marzban/certs"

load_dotenv(env_path)

# Check env exists
if not os.path.exists(env_path):
    print(f"Environment file not found at {env_path}.")
    exit(1)

# Configuration
bot_token = os.environ.get('DISCORD_BOT_TOKEN')
channel_id_str = os.environ.get('DISCORD_CHANNEL_ID')
backup_interval_time_str = os.environ.get('BACKUP_INTERVAL_TIME')

if bot_token is None or channel_id_str is None or backup_interval_time_str is None:
    print("Please set the DISCORD_BOT_TOKEN, DISCORD_CHANNEL_ID, and BACKUP_INTERVAL_TIME environment variables.")
    exit(1)

try:
    channel_id = int(channel_id_str)
    backup_interval_time = int(backup_interval_time_str)
except ValueError:
    print("DISCORD_CHANNEL_ID and BACKUP_INTERVAL_TIME must be valid integers.")
    exit(1)

sql_alchemy_database_url = os.environ.get('SQLALCHEMY_DATABASE_URL')
xray = os.environ.get('XRAY_JSON')
templates = os.environ.get('CUSTOM_TEMPLATES_DIRECTORY')
db_password = os.environ.get('MYSQL_ROOT_PASSWORD')

dirs_to_include = [docker_path, certs, templates, xray, env_path]
dirs_to_include = [directory for directory in dirs_to_include if os.path.exists(directory)]

# Initialize the bot after loading environment variables
intents = discord.Intents.default()
intents.typing = False
intents.presences = False

# Initialize the bot
bot = commands.Bot(command_prefix='!', intents=intents)

@bot.event
async def on_ready():
    print(f'Logged in as {bot.user.name}')
    while True:
        await send_database_backup(sql_alchemy_database_url, dirs_to_include)
        print(f'Sleeping for {backup_interval_time} minutes...')
        await asyncio.sleep(backup_interval_time * 60)  # Convert minutes to seconds


async def send_database_backup(sql_alchemy_database_url, dirs_to_include):
    if sql_alchemy_database_url.startswith('sqlite:///'):

        # Filter out directories that do not exist
        dirs_to_include = [directory for directory in dirs_to_include if os.path.exists(directory)]
        # Remove "sqlite:///" from the start
        sql_alchemy_database_url = sql_alchemy_database_url[len('sqlite:///'):]
        # SQLite backup
        backup_file = f'{db_name}-{time.strftime("%Y-%m-%d_%H:%M")}.tar.gz'
        if dirs_to_include:
            subprocess.run(['tar', 'czvf', os.path.join(backup_dir, backup_file)] + dirs_to_include + [sql_alchemy_database_url], cwd=backup_dir, check=True)
        else:
            print("No directories to include in the backup.")
            subprocess.run(['tar', 'czvf', os.path.join(backup_dir, backup_file)] + [sql_alchemy_database_url], cwd=backup_dir, check=True)
        # Send the backup file to Discord
        channel = bot.get_channel(channel_id)
        if channel:
            await channel.send(file=discord.File(os.path.join(backup_dir, backup_file)))
            print(f'Backup sent to Discord.')
        else:
            print(f'Channel with ID {channel_id} not found.')

        os.remove(os.path.join(backup_dir, backup_file))

    else:

        backup_file = f'{db_name}-{time.strftime("%Y-%m-%d_%H:%M")}.sql.gz'
        backup_path = os.path.join(backup_dir, backup_file)
        sql_dir = os.path.join(backup_dir, f"{db_name}.sql")

        # Check if the database dump file exists before attempting to create the gzip file
        subprocess.run(
            [
                "docker", "compose", "-f", docker_path, "exec", container_name,
                "mysqldump", "-u", "root", "-p" + db_password, db_name
            ],
            stdout=open(backup_path, "w"),
            check=True,
            shell=True
        )

        subprocess.run(['tar', 'rvf', backup_path] + dirs_to_include + [sql_dir], check=True)

        # Send the backup file to Discord
        channel = bot.get_channel(channel_id)
        if channel:
            await channel.send(file=discord.File(backup_path))
            print(f'Backup sent to Discord.')
        else:
            print(f'Channel with ID {channel_id} not found.')

    os.remove(backup_path)
    os.remove(sql_dir)


# Run the bot
bot.run(bot_token)
