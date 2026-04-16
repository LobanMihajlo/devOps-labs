#!/bin/bash
set -e

echo "--- [1/3] Installing System Dependencies ---"
sudo apt update
sudo apt install -y nodejs npm postgresql postgresql-contrib

echo "--- [2/3] Setting up Database & Config ---"
chmod +x ./src/scripts/pg.sh
./src/scripts/pg.sh

echo "--- [3/3] Preparing App & Starting ---"
npm install
node ./src/migrations/migrate.js

echo "Starting Task Tracker on port 5000..."
node ./src/app.js