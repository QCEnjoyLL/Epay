FROM php:8.2-apache

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libgmp-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libzip-dev \
        unzip; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        curl \
        exif \
        gd \
        gmp \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        zip; \
    a2enmod headers rewrite; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php/epay.ini /usr/local/etc/php/conf.d/epay.ini
COPY docker/entrypoint.sh /usr/local/bin/epay-entrypoint
COPY . /var/www/html

RUN set -eux; \
    chmod +x /usr/local/bin/epay-entrypoint; \
    chown -R www-data:www-data /var/www/html

ENTRYPOINT ["epay-entrypoint"]
CMD ["apache2-foreground"]
