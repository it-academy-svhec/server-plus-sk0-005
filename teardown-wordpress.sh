#!/usr/bin/env bash
# uninstall-wordpress-lab.sh
# Fully reverses install-wordpress-latest-lab.sh
# Ubuntu 20.04
#
# Usage: sudo ./uninstall-wordpress-lab.sh [DB_NAME] [DB_USER]
#        (same defaults as the installer: wordpress / wpuser)
# Set FORCE=1 to skip the confirmation prompt.
#
# WARNING: This is destructive. It drops the database, deletes the web root,
# and PURGES Apache, MySQL, and PHP including ALL MySQL data and configs.

set -uo pipefail

DB_NAME="${1:-wordpress}"
DB_USER="${2:-wpuser}"
APACHE_ROOT="/var/www/html"

info(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[1;33m[WARN]\e[0m $*"; }
err(){ echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

# Ensure root
if [ "$(id -u)" -ne 0 ]; then
  err "Run as root"
  exit 1
fi

# --- Confirmation ---
if [ "${FORCE:-0}" != "1" ]; then
  warn "This will PERMANENTLY remove:"
  echo "  - MySQL database '${DB_NAME}' and user '${DB_USER}'"
  echo "  - Everything in ${APACHE_ROOT}"
  echo "  - Apache, MySQL, PHP packages, configs, logs, and ALL MySQL data"
  echo "  - WordPress download files in /tmp"
  read -r -p "Type 'yes' to continue: " answer
  if [ "$answer" != "yes" ]; then
    info "Aborted."
    exit 0
  fi
fi

export DEBIAN_FRONTEND=noninteractive

# --- Database cleanup (must happen while MySQL is still installed) ---
if command -v mysql >/dev/null 2>&1; then
  info "Starting MySQL (if needed) to remove database and user..."
  systemctl start mysql 2>/dev/null || true

  info "Dropping database and user..."
  mysql -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`;" || warn "Could not drop database"
  mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;" || warn "Could not drop user"
else
  warn "mysql client not found; skipping database cleanup"
fi

# --- Stop and disable services ---
info "Stopping and disabling apache2 and mysql..."
systemctl disable --now apache2 2>/dev/null || true
systemctl disable --now mysql 2>/dev/null || true

# --- Remove WordPress files ---
info "Removing WordPress from ${APACHE_ROOT}..."
rm -rf "${APACHE_ROOT:?}"/* "${APACHE_ROOT:?}"/.[!.]* 2>/dev/null || true

info "Removing downloaded WordPress files from /tmp..."
rm -rf /tmp/wordpress /tmp/latest.tar.gz

# --- Remove packages ---
info "Purging installed packages..."
apt-get purge -y \
  apache2 apache2-bin apache2-data apache2-utils \
  libapache2-mod-php 'libapache2-mod-php7.*' \
  mysql-server 'mysql-server-*' mysql-client 'mysql-client-*' mysql-common \
  php php-mysql php-common 'php7.*' \
  || warn "Some packages could not be purged"

# wget and unzip are very common utilities and may have been present before
# the install, so they are left alone by default. Uncomment to remove them.
# apt-get purge -y wget unzip

info "Removing unused dependencies..."
apt-get autoremove -y --purge
apt-get autoclean -y

# --- Remove leftover data/config/log directories ---
info "Removing leftover config, data, and log directories..."
rm -rf /etc/apache2 /var/log/apache2 /var/lib/apache2
rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/lib/mysql-files /var/lib/mysql-keyring /run/mysqld
rm -rf /etc/php /var/lib/php
rm -rf "${APACHE_ROOT}"
rmdir /var/www 2>/dev/null || true

# Remove users/groups that might be left behind (usually removed by purge)
userdel mysql 2>/dev/null || true
groupdel mysql 2>/dev/null || true

systemctl daemon-reload

cat <<EOF

DONE.

Removed:
  - Database '${DB_NAME}' and user '${DB_USER}'
  - WordPress files and web root (${APACHE_ROOT})
  - Apache, MySQL, and PHP packages, configs, data, and logs

Not removed:
  - wget and unzip (shared utilities)
  - Any firewall rules you added during lab testing (e.g. ufw/iptables
    rules for ports 80, 3306, 22) -- review these manually:
      sudo ufw status numbered

EOF
