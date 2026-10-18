# syntax=docker/dockerfile:1
# ─────────────────────────────────────────────────────────────────────────────
# Image de DÉVELOPPEMENT de l'API : PHP 8.4 + FrankenPHP (serveur web) + extensions.
# Le code n'est pas copié dans l'image : il est monté depuis ./api (compose.yaml).
# ─────────────────────────────────────────────────────────────────────────────
FROM dunglas/frankenphp:1-php8.4 AS api

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
WORKDIR /app

# Outils et extensions PHP : Composer, cache APCu, internationalisation (contrainte Country),
# OPcache, zip (Composer), pilote PostgreSQL.
RUN apt-get update \
 && apt-get install -y --no-install-recommends git unzip file \
 && install-php-extensions @composer apcu intl opcache zip pdo_pgsql \
 && rm -rf /var/lib/apt/lists/*

ENV APP_ENV=dev \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PHP_INI_SCAN_DIR=":/usr/local/etc/php/app.conf.d"

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
 && git config --system --add safe.directory /app

COPY --link frankenphp/app.ini /usr/local/etc/php/app.conf.d/10-app.ini
COPY --link frankenphp/Caddyfile /etc/frankenphp/Caddyfile
COPY --link --chmod=755 frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile"]
