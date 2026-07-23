#!/bin/sh
set -e

if [ -n "${DB_HOST:-}" ]; then
    echo "Waiting for database at ${DB_HOST}:${DB_PORT:-5432}..."

    attempts=0
    max_attempts=60

    until php -r '
$host = getenv("DB_HOST");
$port = (int) (getenv("DB_PORT") ?: 5432);
$errno = 0;
$errstr = "";
$connection = @fsockopen($host, $port, $errno, $errstr, 2);

if ($connection !== false) {
    fclose($connection);
    exit(0);
}

exit(1);
'; do
        attempts=$((attempts + 1))

        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "Database is still unavailable after ${max_attempts} attempts."
            exit 1
        fi

        sleep 2
    done
fi

php artisan migrate --force

if [ "${RUN_DB_SEED:-false}" = "true" ]; then
    php artisan db:seed --force
fi

exec php artisan serve --host=0.0.0.0 --port="${PORT:-10000}"