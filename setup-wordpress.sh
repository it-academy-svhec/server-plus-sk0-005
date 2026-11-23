#!/usr/bin/env bash
# install-wordpress-latest-lab.sh  (idempotent / non-destructive version)
# One-step WordPress lab setup using latest official WordPress
# Ubuntu 20.04
#
# Safe to re-run: existing WordPress files, wp-config.php, uploads, themes,
# plugins, database content, and the DB user's password are never overwritten.

set -euo pipefail

# --- Defaults (override via args) ---
DB_NAME="${1:-wordpress}"
DB_USER="${2:-wpuser}"
DB_PASS="${3:-password}"
APACHE_ROOT="/var/www/html"
WP_CONFIG="${APACHE_ROOT}/wp-config.php"

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
apt-get update -y

info "Installing required packages (already-installed ones are skipped)..."
apt-get install -y apache2 mysql-server php php-mysql libapache2-mod-php wget unzip

info "Enabling and starting apache2 and mysql..."
systemctl enable --now apache2
systemctl enable --now mysql

# --- Database setup ---
info "Ensuring database exists..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

if [ -f "$WP_CONFIG" ]; then
  # An existing wp-config.php holds the credentials WordPress is already using.
  # Don't touch the DB user's password or we could break a working site.
  warn "wp-config.php already exists; leaving DB user password unchanged."
  mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
else
  info "Ensuring DB user exists with the requested password..."
  mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
fi
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# --- WordPress files ---
mkdir -p "${APACHE_ROOT}"

if [ -f "${APACHE_ROOT}/wp-includes/version.php" ]; then
  info "WordPress core already present in ${APACHE_ROOT}; skipping download and copy."
else
  # Remove only Apache's stock placeholder page, which would otherwise be
  # served in preference to WordPress's index.php. Custom index.html is kept.
  if [ -f "${APACHE_ROOT}/index.html" ] && grep -q "Apache2 Ubuntu Default Page" "${APACHE_ROOT}/index.html"; then
    info "Removing Apache default placeholder page..."
    rm -f "${APACHE_ROOT}/index.html"
  fi

  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "$WORKDIR"' EXIT

  info "Downloading latest WordPress..."
  wget -q -O "${WORKDIR}/latest.tar.gz" https://wordpress.org/latest.tar.gz
  tar xzf "${WORKDIR}/latest.tar.gz" -C "${WORKDIR}"

  info "Copying WordPress to web root (no-clobber, includes dotfiles)..."
  cp -rn "${WORKDIR}/wordpress/." "${APACHE_ROOT}/"

  chown -R www-data:www-data "${APACHE_ROOT}"
  chmod -R 755 "${APACHE_ROOT}"
fi

# --- WordPress config ---
if [ -f "$WP_CONFIG" ]; then
  info "wp-config.php already exists; leaving it untouched."
else
  info "Creating wp-config.php..."
  cat > "$WP_CONFIG" <<EOF
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASS}');
define('DB_HOST', 'localhost');
define('FS_METHOD', 'direct');

define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

\$table_prefix = 'wp_';

define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */
if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
EOF
  chown www-data:www-data "$WP_CONFIG"
  chmod 640 "$WP_CONFIG"
fi

# --- Restart Apache ---
info "Reloading Apache..."
systemctl reload apache2 || systemctl restart apache2

cat <<EOF

DONE.

WordPress (latest) should now load at:
  http://<server_ip>/

Database:
  name: ${DB_NAME}
  user: ${DB_USER}
  host: localhost (3306)
  pass: ${DB_PASS}   (only applied if wp-config.php did not already exist)

Lab testing suggestions:
- Block port 3306 to prevent direct DB access
- Allow/block port 80 to control web access
- Restrict SSH (22) to admin subnet
- Test path-based access restrictions (/wp-admin)

EOF
