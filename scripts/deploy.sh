#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="10.17.200.30"
SSH_KEY="$HOME/.ssh/id_rsa_server"
REMOTE_PLUGIN_DIR="/home/steam/cs2server/game/csgo/addons/counterstrikesharp/plugins/MatchZy"
LOCAL_BUILD_DIR="D:/CS2-Prac/bin/Release/net10.0/."

echo "== Building MatchZy =="
cd "D:/CS2-Prac"
dotnet build MatchZy.csproj -c Release

echo "== Deploying to $REMOTE_HOST =="
scp -i "$SSH_KEY" -r "$LOCAL_BUILD_DIR" "root@$REMOTE_HOST:$REMOTE_PLUGIN_DIR/"
ssh -i "$SSH_KEY" "root@$REMOTE_HOST" "chown -R steam:steam $REMOTE_PLUGIN_DIR"

echo "== Restarting cs2server.service =="
ssh -i "$SSH_KEY" "root@$REMOTE_HOST" "systemctl restart cs2server.service"
sleep 20

echo "== Plugin status =="
ssh -i "$SSH_KEY" "root@$REMOTE_HOST" '
RCON_PW=$(grep RCON_PASSWORD /root/cs2_rcon_password.txt | cut -d= -f2)
mcrcon -H 127.0.1.1 -P 27015 -p $RCON_PW "css_plugins list"
'

echo "== Tailing logs (Ctrl+C to stop) =="
ssh -i "$SSH_KEY" "root@$REMOTE_HOST" "journalctl -u cs2server.service -f"
