#!/bin/bash
set -e

APP_DIR="/opt/mywebapp"

echo "--- [1/6] Installing System Dependencies ---"
sudo apt update
sudo apt install -y nodejs npm postgresql postgresql-contrib nginx

echo "--- [2/6] Setting up Database & Config ---"
chmod +x ./src/scripts/pg.sh
./src/scripts/pg.sh

echo "--- [3/6] Creating Users & Permissions ---"
chmod +x ./src/scripts/users.sh
./src/scripts/users.sh

echo "--- [4/6] Deploying App to $APP_DIR ---"
sudo mkdir -p "$APP_DIR"
sudo cp -a ./src "$APP_DIR/"
sudo cp -a ./package.json "$APP_DIR/"
if [ -f ./package-lock.json ]; then
	sudo cp -a ./package-lock.json "$APP_DIR/"
fi
sudo chown -R app:app "$APP_DIR"

echo "--- [5/6] Installing App Dependencies in $APP_DIR ---"
sudo rm -rf "$APP_DIR/node_modules"
if [ -f "$APP_DIR/package-lock.json" ]; then
	sudo -u app HOME=/var/lib/app npm --prefix "$APP_DIR" ci
else
	sudo -u app HOME=/var/lib/app npm --prefix "$APP_DIR" install
fi

echo "--- [6/6] Configuring Systemd Socket Activation ---"
chmod +x ./src/scripts/systemd.sh
./src/scripts/systemd.sh

echo "Setup complete."
echo "Trigger app start via socket: curl -i http://127.0.0.1:5000/health/alive"