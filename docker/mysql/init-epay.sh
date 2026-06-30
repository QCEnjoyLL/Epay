#!/bin/sh
set -e

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
: "${EPAY_DB_PREFIX:=pay}"

tmp_sql="$(mktemp)"
sed "s/pre_/${EPAY_DB_PREFIX}_/g" /docker-entrypoint-initdb.d/install.sql.template > "$tmp_sql"

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < "$tmp_sql"
mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" <<SQL
INSERT IGNORE INTO \`${EPAY_DB_PREFIX}_config\` VALUES ('syskey', MD5(CONCAT(RAND(), NOW())));
INSERT IGNORE INTO \`${EPAY_DB_PREFIX}_config\` VALUES ('build', CURDATE());
INSERT IGNORE INTO \`${EPAY_DB_PREFIX}_config\` VALUES ('cronkey', FLOOR(111111 + RAND() * 888888));
SQL

rm -f "$tmp_sql"
