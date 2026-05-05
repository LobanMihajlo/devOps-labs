#!/bin/bash
set -e
N=19
DEFAULT_VM_USER="${DEFAULT_VM_USER:-ubuntu}"

echo ">>> Creating System Users"

if ! id "app" &>/dev/null; then
    sudo useradd --system --home-dir /var/lib/app --create-home --shell /usr/sbin/nologin app
    echo "User 'app' created."
fi

sudo usermod -d /var/lib/app app
sudo mkdir -p /var/lib/app
sudo chown app:app /var/lib/app

if ! id "student" &>/dev/null; then
    sudo useradd -m -s /bin/bash student
    echo "student:12345678" | sudo chpasswd
    sudo chage -d 0 student
    echo "User 'student' created."
fi
sudo usermod -aG sudo student

if ! id "teacher" &>/dev/null; then
    sudo useradd -m -s /bin/bash teacher
    echo "teacher:12345678" | sudo chpasswd
    sudo chage -d 0 teacher
    echo "User 'teacher' created."
fi
sudo usermod -aG sudo teacher

if ! getent group operator > /dev/null; then
    sudo groupadd operator
fi

if ! id "operator" &>/dev/null; then
    sudo useradd -m -g operator -s /bin/bash operator
    echo "operator:12345678" | sudo chpasswd
    sudo chage -d 0 operator
fi

echo ">>> Configuring Restricted Sudo for 'operator'"
cat <<EOF | sudo tee /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload
EOF

echo ">>> Creating Gradebook"
echo "$N" | sudo tee /home/student/gradebook > /dev/null
sudo chown student:student /home/student/gradebook

echo ">>> Locking default VM user (if configured and present)"
if id "$DEFAULT_VM_USER" &>/dev/null; then
    if [[ "$DEFAULT_VM_USER" != "student" && "$DEFAULT_VM_USER" != "teacher" && "$DEFAULT_VM_USER" != "operator" && "$DEFAULT_VM_USER" != "app" ]]; then
        sudo usermod -L "$DEFAULT_VM_USER"
        sudo usermod -s /usr/sbin/nologin "$DEFAULT_VM_USER"
        echo "Locked default user '$DEFAULT_VM_USER'."
    fi
fi