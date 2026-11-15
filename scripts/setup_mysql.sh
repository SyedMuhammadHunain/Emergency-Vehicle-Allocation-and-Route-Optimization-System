#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo " Res-Q: MariaDB/MySQL Setup for Arch Linux"
echo "========================================================"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root / sudo." >&2
  exit 1
fi

# Initialize data directory if not already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[1/3] Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi

echo "[2/3] Starting MariaDB service..."
systemctl enable --now mariadb

echo "[3/3] Creating resq_db and provisioning resq user..."
mariadb -e "CREATE DATABASE IF NOT EXISTS resq_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mariadb -e "CREATE USER IF NOT EXISTS 'resq'@'localhost' IDENTIFIED BY 'NewPass123';"
mariadb -e "ALTER USER 'resq'@'localhost' IDENTIFIED BY 'NewPass123';"
mariadb -e "GRANT ALL PRIVILEGES ON resq_db.* TO 'resq'@'localhost';"
mariadb -e "CREATE USER IF NOT EXISTS 'resq'@'127.0.0.1' IDENTIFIED BY 'NewPass123';"
mariadb -e "ALTER USER 'resq'@'127.0.0.1' IDENTIFIED BY 'NewPass123';"
mariadb -e "GRANT ALL PRIVILEGES ON resq_db.* TO 'resq'@'127.0.0.1';"
mariadb -e "FLUSH PRIVILEGES;"

echo "Verifying connection..."
mariadb -u resq -pNewPass123 -h 127.0.0.1 -e "SHOW DATABASES LIKE 'resq_db';"
echo "========================================================"
echo " MariaDB/MySQL provisioning complete!"
echo "========================================================"
