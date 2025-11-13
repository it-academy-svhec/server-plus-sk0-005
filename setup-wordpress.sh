#!/usr/bin/env bash
# install-wordpress-lab.sh
# One-step WordPress + MySQL lab setup for Ubuntu 20
# Installs Apache2, MariaDB, PHP, WordPress
# Sets WordPress to load at root URL

set -euo pipefail

# --- Defaults (override via args) ---
DB_NAME="${1:-wordpress}"
DB_USER="${2:-wpuser}"
DB_PASS="${3:-password}"
WP_CONTENT_DIR="/usr/share/wordpress/wp-content"
CONFIG_DIR="/etc/wordpress"
CONFIG_DEFAULT="${CONFIG_DIR}/config-default.php"
APACHE_ROOT="/var/www/html"

info(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[1;33m[WARN]\e[0m $*"; }
err(){ echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  err "This script must be run as root. Use sudo."
  exit 1
fi

info "Updating package index..."
export DEBIAN_FRONTEND=noninteractive
apt update -y

info "Installing packages: apache2 mysql-server php php-mysql libapache2-mod-php wordpress git -y"
apt install -y apache2 mysql-server php libapache2-mod-php php-mysql wordpress git

info "Enabling and starting apache2 and mysql services..."
systemctl enable --now apache2
systemctl enable --now mysql

# --- Database setup ---
info "Creating database and user (DB: ${DB_NAME}, USER: ${DB_USER})..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# --- WordPress web root setup ---
info "Removing default Apache page and old files..."
rm -rf ${APACHE_ROOT}/*

info "Copying WordPress files to ${APACHE_ROOT}..."
cp -r /usr/share/wordpress/* ${APACHE_ROOT}/
chown -R www-data:www-data ${APACHE_ROOT}
chmod -R 755 ${APACHE_ROOT}

# --- WordPress config ---
info "Creating WordPress config in ${CONFIG_DIR}..."
mkdir -p "${CONFIG_DIR}"

if [ ! -f "${CONFIG_DEFAULT}" ]; then
  cat > "${CONFIG_DEFAULT}" <<EOF
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASS}');
define('DB_HOST', 'localhost');
define('WP_CONTENT_DIR', '${WP_CONTENT_DIR}');
?>
EOF
  info "Wrote ${CONFIG_DEFAULT}"
else
  warn "${CONFIG_DEFAULT} already exists; leaving it."
fi

HOST_CONF="${CONFIG_DIR}/config-$(hostname -f).php"
if [ ! -e "${HOST_CONF}" ]; then
  ln -s "${CONFIG_DEFAULT}" "${HOST_CONF}"
  info "Created hostname-linked config: ${HOST_CONF}"
else
  info "Hostname-specific config already exists: ${HOST_CONF}"
fi

info "Restarting Apache..."
systemctl restart apache2

cat <<EOF

DONE.

WordPress should now load at:
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
- Test path-based access restrictions if desired (e.g., /wp-admin)

EOF
