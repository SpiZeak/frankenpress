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

- `[www/](www/)` ← WordPress root (core files, themes, plugins, media, etc.). Treat it as your working tree when customizing PHP, JS, or theme files.
- `[data/](data/)` ← Persistent storage for Caddy (locks, certificates) and MariaDB data directories mounted into the container. Do not delete it if you want to keep your site data.
- `[config/](config/)` ← Additional configuration fragments consumed by FrankenPHP/Caddy.
- `[caddy/Caddyfile](caddy/Caddyfile)` and `[caddy/Caddyfile.d](caddy/Caddyfile.d)` ← Caddy configuration served inside the container; edit these to change TLS, redirects, or HTTP/3 settings and reload the container.
- `[scripts/entrypoint.sh](scripts/entrypoint.sh)` ← Boot script invoked by the container. It downloads WordPress, bootstraps `wp-config.php`, waits for MariaDB, and installs Query Monitor by default.

## Helpers & maintenance

- Run `docker compose exec php wp <command>` to operate WP-CLI; e.g., `docker compose exec php wp plugin list`.
- The container ships with `mariadb-client`, so you can execute `docker compose exec php mysql -h mariadb -u wpuser -pwppass wordpress` if you prefer native SQL.
- PHP extensions are added via `install-php-extensions` inside [Dockerfile](Dockerfile); edit that file if you need additional PHP modules.
- To rebuild the image after changing PHP extensions or other build-time files, run `docker compose build php`.

## Development tips

- Keep `www/wp-content/uploads` and other user-generated assets outside version control by committing only themes/plugins you edit.
- Back up `data/` before wiping containers so MariaDB credentials and TLS state survive.
- The `php` service binds ports `80`, `443` (and `443/udp` for HTTP/3); change them in [compose.yml](compose.yml) when they conflict with other services.

## Troubleshooting

- `docker compose logs php` shows both WordPress bootstrap progress and Caddy logs.
- If WordPress reports "Error establishing a database connection", make sure MariaDB is healthy (`docker compose ps` and `docker compose logs mariadb`).
- To force a fresh WordPress install, remove `www/wp-config.php` and restart the stack; the entrypoint script will recreate the config and run `wp core install` again.
