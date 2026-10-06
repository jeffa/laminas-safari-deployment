FROM php:8.1-apache

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public \
    COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        ca-certificates \
        patch \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        curl \
        dom \
        gd \
        intl \
        mbstring \
        pdo_mysql \
        soap \
        xml \
        zip \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
COPY app/ /var/www/html/
COPY runtime-config/local.php /var/www/html/config/autoload/local.php
COPY patches/email-smtp.patch /tmp/email-smtp.patch
COPY patches/waiver-dropoff.patch /tmp/waiver-dropoff.patch

RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
    && patch -p1 < /tmp/email-smtp.patch \
    && patch -p1 < /tmp/waiver-dropoff.patch \
    && rm -f /tmp/email-smtp.patch /tmp/waiver-dropoff.patch \
    && mkdir -p data/cache \
    && ln -s /var/www/html/module/Application/src/Controller/Helper/PHPMailer /var/www/html/PHPMailer \
    && ln -s /var/www/html/assets /var/www/html/public/assets \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80
