#!/usr/bin/env sh
set -eu

WORDPRESS_PATH="/app/www/localhost"

# Raise memory limit for wp-cli operations.
WP_CLI_PHP_ARGS="${WP_CLI_PHP_ARGS:--d memory_limit=512M}"
export WP_CLI_PHP_ARGS

wp_cli() {
  php $WP_CLI_PHP_ARGS /usr/local/bin/wp "$@"
}

DB_HOST="${WP_DB_HOST:-mariadb}"
DB_NAME="${WP_DB_NAME:-database}"
DB_USER="${WP_DB_USER:-root}"
DB_PASSWORD="${WP_DB_PASSWORD:-root}"

SITE_URL="${WP_SITE_URL:-http://localhost}"
SITE_TITLE="${WP_SITE_TITLE:-WordPress}"
ADMIN_USER="${WP_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-admin}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
ENABLE_QUERY_MONITOR="${WP_ENABLE_QUERY_MONITOR:-0}"

if [ ! -f "$WORDPRESS_PATH/wp-load.php" ]; then
  echo "WordPress core not found; downloading..."
  wp_cli core download --path="$WORDPRESS_PATH"
fi

if [ ! -f "$WORDPRESS_PATH/wp-config.php" ]; then
  echo "Creating wp-config.php..."
  wp_cli config create \
    --path="$WORDPRESS_PATH" \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="$DB_HOST"
fi

attempts=0
max_attempts=30
while ! wp_cli db check --path="$WORDPRESS_PATH" >/dev/null 2>&1; do
  echo "Attempting to connect to database... ($((attempts + 1))/$max_attempts)"
  attempts=$((attempts + 1))
  if [ "$attempts" -ge "$max_attempts" ]; then
    echo "Database not ready; skipping WordPress install."
    break
  fi
  sleep 2
done

echo "Database connection successful."
echo "Checking WordPress installation..."

if wp_cli db check --path="$WORDPRESS_PATH" >/dev/null 2>&1; then
  if ! wp_cli core is-installed --path="$WORDPRESS_PATH" >/dev/null 2>&1; then
    echo "Installing WordPress..."
    wp_cli core install \
      --path="$WORDPRESS_PATH" \
      --url="$SITE_URL" \
      --title="$SITE_TITLE" \
      --admin_user="$ADMIN_USER" \
      --admin_password="$ADMIN_PASSWORD" \
      --admin_email="$ADMIN_EMAIL"
    echo "WordPress installed successfully."
  else
    echo "WordPress is already installed."
  fi

  # Install Query Monitor only when explicitly enabled.
  if [ "$ENABLE_QUERY_MONITOR" = "1" ]; then
    if ! wp_cli plugin is-installed query-monitor --path="$WORDPRESS_PATH" >/dev/null 2>&1; then
      wp_cli plugin install query-monitor --activate --path="$WORDPRESS_PATH"
    else
      wp_cli plugin activate query-monitor --path="$WORDPRESS_PATH" >/dev/null 2>&1 || true
    fi
  fi
fi

echo "Starting up server..."
exec /usr/local/bin/docker-php-entrypoint "$@"
