#!/bin/bash
set -e

echo "--- [1/4] Installing System Dependencies ---"
sudo apt update
sudo apt install -y nodejs npm postgresql postgresql-contrib

echo "--- [2/4] Setting up Database & Config ---"
chmod +x ./src/scripts/pg.sh
./src/scripts/pg.sh

echo "--- [3/4] Installing App Dependencies ---"
npm install

echo "--- [4/4] Configuring Systemd Socket Activation ---"
chmod +x ./src/scripts/systemd.sh
./src/scripts/systemd.sh

echo "Setup complete."
echo "Trigger app start via socket: curl -i http://127.0.0.1:5000/health/alive"