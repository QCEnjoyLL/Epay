#!/bin/sh
set -eu

if [ -n "${DB_HOST:-}" ] && [ -n "${DB_NAME:-}" ] && [ -n "${DB_USER:-}" ]; then
    php <<'PHP'
<?php
$host = getenv('DB_HOST') ?: 'db';
$port = (int)(getenv('DB_PORT') ?: 3306);
$user = getenv('DB_USER') ?: '';
$password = getenv('DB_PASSWORD') ?: '';
$database = getenv('DB_NAME') ?: '';
$prefix = getenv('DB_PREFIX') ?: 'pay';

if (!preg_match('/^[A-Za-z0-9_]+$/', $prefix)) {
    fwrite(STDERR, "Invalid DB_PREFIX. Use letters, numbers, and underscores only.\n");
    exit(1);
}

$config = [
    'host' => $host,
    'port' => $port,
    'user' => $user,
    'pwd' => $password,
    'dbname' => $database,
    'dbqz' => $prefix,
];

file_put_contents(
    '/var/www/html/config.php',
    "<?php\n/* database config */\n\$dbconfig = ".var_export($config, true).";\n"
);

if ((getenv('EPAY_AUTO_INSTALL') ?: '1') === '0') {
    exit(0);
}

$dsn = "mysql:host={$host};dbname={$database};port={$port};charset=utf8mb4";
$pdo = null;
$lastError = null;
for ($i = 0; $i < 60; $i++) {
    try {
        $pdo = new PDO($dsn, $user, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        break;
    } catch (Throwable $e) {
        $lastError = $e;
        sleep(2);
    }
}

if (!$pdo) {
    fwrite(STDERR, "Could not connect to database: ".$lastError->getMessage()."\n");
    exit(1);
}

$pdo->exec("set sql_mode = ''");
$pdo->exec("set names utf8mb4");
$pdo->exec("set time_zone = '+8:00'");

$configTable = $prefix.'_config';
try {
    $pdo->query("SELECT 1 FROM `{$configTable}` LIMIT 1");
    exit(0);
} catch (Throwable $e) {
    // The application schema is not installed yet.
}

$sqlFile = '/var/www/html/install/install.sql';
if (!is_file($sqlFile)) {
    fwrite(STDERR, "Missing {$sqlFile}; cannot initialize database.\n");
    exit(1);
}

$sql = str_replace('pre_', $prefix.'_', file_get_contents($sqlFile));
$statements = array_filter(array_map('trim', explode(';', $sql)));
$statements[] = "INSERT IGNORE INTO `{$configTable}` VALUES ('syskey', '".bin2hex(random_bytes(16))."')";
$statements[] = "INSERT IGNORE INTO `{$configTable}` VALUES ('build', '".date('Y-m-d')."')";
$statements[] = "INSERT IGNORE INTO `{$configTable}` VALUES ('cronkey', '".random_int(111111, 999999)."')";

foreach ($statements as $statement) {
    if ($statement !== '') {
        $pdo->exec($statement);
    }
}

fwrite(STDOUT, "Epay database initialized with prefix {$prefix}_\n");
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
