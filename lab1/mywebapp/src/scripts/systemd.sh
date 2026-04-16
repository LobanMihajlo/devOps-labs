#!/bin/bash
set -e

PORT=5000
APP_DIR="/opt/mywebapp"

echo ">>> Configuring Systemd Socket Activation (Port $PORT)"

cat <<EOF | sudo tee /etc/systemd/system/mywebapp.socket
[Unit]
Description=Socket for My Web App (N=19)

[Socket]
ListenStream=$PORT
Service=mywebapp.service

[Install]
WantedBy=sockets.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/mywebapp.service
[Unit]
Description=My Web App Service
After=network.target postgresql.service
Requires=mywebapp.socket

[Service]
User=app
Group=app
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production

# Perform migration before launch 
ExecStartPre=/usr/bin/node $APP_DIR/src/migrations/migrate.js
# Start the app 
ExecStart=/usr/bin/node $APP_DIR/src/app.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Reloading Systemd and enabling Socket"
sudo systemctl daemon-reload

sudo systemctl enable --now mywebapp.socket

echo "Systemd configuration complete. App will start when port $PORT is accessed."