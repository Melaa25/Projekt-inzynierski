FROM php:8.4-cli

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip libpq-dev libzip-dev \
    && docker-php-ext-install pdo_pgsql zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN chmod +x /var/www/html/docker-entrypoint.sh

RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 10000

ENTRYPOINT ["/var/www/html/docker-entrypoint.sh"]