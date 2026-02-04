# FrankenPHP WordPress stack

This repository builds on [Dockerfile](Dockerfile) against the `dunglas/frankenphp` base image and wires it together with MariaDB via [compose.yml](compose.yml) to deliver a self-hosted WordPress instance served by Caddy.

## Quick start

1. Install Docker + Compose (Docker Desktop, Podman Compose, etc.).
2. (Optional) Configure secrets by exporting the environment variables documented below or place them into a `.env` file in the repository root.
3. Run `docker compose up -d` and wait for the `php` service to finish the WordPress install flow from [scripts/entrypoint.sh](scripts/entrypoint.sh).
4. Open `http://localhost` and log in using the values shown in the environment table below (or your overrides).
5. Stop the stack with `docker compose down` when you are done.

## Environment variables

| Variable            | Description                                         | Default             |
| ------------------- | --------------------------------------------------- | ------------------- |
| `WP_DB_HOST`        | MariaDB hostname used by WordPress                  | `mariadb`           |
| `WP_DB_NAME`        | Database name                                       | `wordpress`         |
| `WP_DB_USER`        | Database user                                       | `wpuser`            |
| `WP_DB_PASSWORD`    | Database password                                   | `wppass`            |
| `WP_SITE_URL`       | WordPress site URL                                  | `http://localhost`  |
| `WP_SITE_TITLE`     | WordPress site title                                | `WordPress`         |
| `WP_ADMIN_USER`     | Administrator username created by `wp core install` | `admin`             |
| `WP_ADMIN_PASSWORD` | Administrator password                              | `admin`             |
| `WP_ADMIN_EMAIL`    | Administrator email                                 | `admin@example.com` |

Export any overrides in your shell or define them in a `.env` file before invoking Compose to keep these values consistent between restarts.

## Key directories

- `[www/](www/)` ← Host-mounted web root. The container installs WordPress into `www/localhost/`.
- `[www/localhost/](www/localhost/)` ← WordPress site root (core files, themes, plugins, media, etc.). Treat this as your working tree when customizing themes/plugins.
- `[caddy/Caddyfile](caddy/Caddyfile)` ← Global Caddy config; it imports all site definitions from `caddy/sites/*`.
- `[caddy/sites/](caddy/sites/)` ← Per-site Caddy configs (this repo ships `caddy/sites/localhost`).
- `[scripts/entrypoint.sh](scripts/entrypoint.sh)` ← Container boot script. It downloads WordPress (if missing), bootstraps `wp-config.php`, waits for MariaDB, installs WordPress, and activates Query Monitor.

Persistent storage is handled via named Compose volumes (`caddy_data`, `caddy_config`, `mariadb_data`, `mariadb_config`), not repo folders.

## Helpers & maintenance

- Run WP-CLI via `docker compose exec php wp --path=/app/www/localhost <command>`; e.g., `docker compose exec php wp --path=/app/www/localhost plugin list`.
- The container ships with `mariadb-client`, so you can execute `docker compose exec php mysql -h mariadb -u wpuser -p"wppass" wordpress` if you prefer native SQL.
- PHP extensions are added via `install-php-extensions` inside [Dockerfile](Dockerfile); edit that file if you need additional PHP modules.
- To rebuild the image after changing PHP extensions or other build-time files, run `docker compose build php`.

## Development tips

- Keep `www/localhost/wp-content/uploads` and other user-generated assets outside version control by committing only themes/plugins you edit.
- Back up your named volumes before wiping containers if you want MariaDB data and Caddy TLS state to survive.
- The `php` service binds ports `80`, `443` (and `443/udp` for HTTP/3); change them in [compose.yml](compose.yml) when they conflict with other services.

## Troubleshooting

- `docker compose logs php` shows both WordPress bootstrap progress and Caddy logs.
- If WordPress reports "Error establishing a database connection", make sure MariaDB is healthy (`docker compose ps` and `docker compose logs mariadb`).
- To force a fresh WordPress config bootstrap, remove `www/localhost/wp-config.php` and restart the stack; the entrypoint script will recreate the config.
- To wipe everything (including the database), use `docker compose down -v` to remove containers and named volumes.
