#!/usr/bin/env bash
# install-wordpress-lab-latest.sh
# One-step WordPress lab setup using the latest official WordPress
# Ubuntu 20.04

set -euo pipefail

# --- Defaults (override via args) ---
DB_NAME="${1:-wordpress}"
DB_USER="${2:-wpuser}"
DB_PASS="${3:-password}"
APACHE_ROOT="/var/www/html"
CONFIG_DIR="/etc/wordpress"

info(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[1;33m[WARN]\e[0m $*"; }
err(){ echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

# Ensure root
if [ "$(id -u)" -ne 0 ]; then
  err "Run as root"
  exit 1
fi

info "Updating package index..."
export DEBIAN_FRONTEND=noninteractive
apt update -y

info "Installing required packages..."
apt install -y apache2 mysql-server php php-mysql libapache2-mod-php wget unzip

info "Enabling and starting apache2 and mysql..."
systemctl enable --now apache2
systemctl enable --now mysql

# --- Database setup ---
info "Creating database and user..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# --- Prepare web root ---
info "Cleaning up Apache root..."
rm -rf ${APACHE_ROOT}/*

info "Downloading latest WordPress..."
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

info "Copying WordPress to web root..."
cp -r wordpress/* ${APACHE_ROOT}/
chown -R www-data:www-data ${APACHE_ROOT}
chmod -R 755 ${APACHE_ROOT}

# --- WordPress config ---
info "Creating WordPress config in ${CONFIG_DIR}..."
mkdir -p "${CONFIG_DIR}"
CONFIG_DEFAULT="${CONFIG_DIR}/config-default.php"

if [ ! -f "${CONFIG_DEFAULT}" ]; then
  cat > "${CONFIG_DEFAULT}" <<EOF
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASS}');
define('DB_HOST', 'localhost');
define('WP_CONTENT_DIR', '${APACHE_ROOT}/wp-content');
define('FS_METHOD', 'direct');
?>
EOF
  info "Created ${CONFIG_DEFAULT}"
else
  warn "${CONFIG_DEFAULT} exists, leaving in place."
fi

HOST_CONF="${CONFIG_DIR}/config-$(hostname -f).php"
if [ ! -e "${HOST_CONF}" ]; then
  ln -s "${CONFIG_DEFAULT}" "${HOST_CONF}"
  info "Created hostname-linked config: ${HOST_CONF}"
fi

# --- Restart Apache ---
info "Restarting Apache..."
systemctl restart apache2

cat <<EOF

DONE.

WordPress (latest) should now load at:
  http://<server_ip>/

Database:
  name: ${DB_NAME}
  user: ${DB_USER}
  pass: ${DB_PASS}
  host: localhost (3306)

Lab testing suggestions:
- Block port 3306 to prevent direct DB access
- Allow/block port 80 to control web access
- Restrict SSH (22) to admin subnet
- Path-based access restrictions (/wp-admin) can also be tested

EOF
