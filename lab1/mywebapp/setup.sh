#!/bin/bash
set -e

APP_DIR="/opt/mywebapp"

echo "--- [1/7] Installing System Dependencies ---"
sudo apt update
sudo apt install -y nodejs npm postgresql postgresql-contrib nginx

echo "--- [2/7] Setting up Database & Config ---"
chmod +x ./src/scripts/pg.sh
./src/scripts/pg.sh

echo "--- [3/7] Creating Users & Permissions ---"
chmod +x ./src/scripts/users.sh
./src/scripts/users.sh

echo "--- [4/7] Deploying App to $APP_DIR ---"
sudo mkdir -p "$APP_DIR"
sudo cp -a ./src "$APP_DIR/"
sudo cp -a ./package.json "$APP_DIR/"
if [ -f ./package-lock.json ]; then
	sudo cp -a ./package-lock.json "$APP_DIR/"
fi
sudo chown -R app:app "$APP_DIR"

echo "--- [5/7] Installing App Dependencies in $APP_DIR ---"
sudo rm -rf "$APP_DIR/node_modules"
if [ -f "$APP_DIR/package-lock.json" ]; then
	sudo -u app HOME=/var/lib/app npm --prefix "$APP_DIR" ci
else
	sudo -u app HOME=/var/lib/app npm --prefix "$APP_DIR" install
fi

echo "--- [6/7] Configuring Systemd Socket Activation ---"
chmod +x ./src/scripts/systemd.sh
./src/scripts/systemd.sh

echo "--- [7/7] Configuring Nginx Reverse Proxy ---"
chmod +x ./src/scripts/nginx.sh
./src/scripts/nginx.sh

echo "Setup complete."
echo "Use Nginx endpoint: curl -i http://127.0.0.1/"