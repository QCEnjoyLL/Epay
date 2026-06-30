#!/bin/sh
set -eu

if [ -n "${DB_HOST:-}" ] && [ -n "${DB_NAME:-}" ] && [ -n "${DB_USER:-}" ]; then
    php <<'PHP'
<?php
$config = [
    'host' => getenv('DB_HOST') ?: 'db',
    'port' => (int)(getenv('DB_PORT') ?: 3306),
    'user' => getenv('DB_USER') ?: '',
    'pwd' => getenv('DB_PASSWORD') ?: '',
    'dbname' => getenv('DB_NAME') ?: '',
    'dbqz' => getenv('DB_PREFIX') ?: 'pay',
];

file_put_contents(
    '/var/www/html/config.php',
    "<?php\n/* database config */\n\$dbconfig = ".var_export($config, true).";\n"
);
PHP
fi

if [ "${EPAY_INSTALL_LOCK:-0}" = "1" ]; then
    mkdir -p /var/www/html/install
    if [ ! -f /var/www/html/install/install.lock ]; then
        printf '%s' 'installed by docker' > /var/www/html/install/install.lock
    fi
fi

chown -R www-data:www-data \
    /var/www/html/config.php \
    /var/www/html/install \
    /var/www/html/plugins 2>/dev/null || true

exec docker-php-entrypoint "$@"
