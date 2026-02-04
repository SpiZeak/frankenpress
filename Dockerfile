FROM dunglas/frankenphp:latest

ARG USER=1000

WORKDIR /app

RUN \
	# Use "adduser -D ${USER}" for alpine based distros
	useradd -u ${USER} -m appuser; \
	# Add additional capability to bind to port 80 and 443
	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp; \
	# Give write access to /config/caddy and /data/caddy
	chown -R ${USER}:${USER} /config/caddy /data/caddy

# add additional extensions here:
RUN install-php-extensions \
	mysqli \
	pdo_mysql \
	gd \
	intl \
	zip \
	curl \
	dom \
	exif \
	fileinfo \
	filter \
	hash \
	json \
	mbstring \
	openssl \
	pcre \
	simplexml \
	spl \
	tokenizer \
	xml \
	xmlreader \
	xmlwriter

# mysqlcheck is required by `wp db check`; mariadb-client ships that utility.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

RUN php -r "copy('https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar', '/usr/local/bin/wp');" \
	&& chmod +x /usr/local/bin/wp

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# use development php.ini by default
RUN cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--config","/etc/frankenphp/Caddyfile","--adapter","caddyfile"]

USER ${USER}
