#!/bin/bash
set -e

echo ">>> Configuring Nginx Reverse Proxy"

cat <<'EOF' | sudo tee /etc/nginx/sites-available/mywebapp >/dev/null
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    access_log /var/log/nginx/mywebapp_access.log;
    error_log /var/log/nginx/mywebapp_error.log;

    # Do not expose internal health endpoints through Nginx.
    location ^~ /health/ {
        return 404;
    }

    # Expose root and business endpoints through reverse proxy.
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

echo "Nginx reverse proxy is active on port 80."
