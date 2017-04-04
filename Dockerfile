FROM php:7.1.3-fpm-alpine

# install extensions
# intl, zip, soap
RUN apk add --update --no-cache libintl icu icu-dev libxml2-dev \
    && docker-php-ext-install intl zip soap

# mysqli, pdo, pdo_mysql, pdo_pgsql
RUN apk add --update --no-cache postgresql-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql pdo_pgsql

# mcrypt, gd, iconv
RUN apk add --update --no-cache \
        freetype-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd

RUN docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" bcmath

# gmp
RUN apk add --update --no-cache gmp gmp-dev \
    && docker-php-ext-install gmp

# php-redis
ENV PHPREDIS_VERSION 3.0.0

RUN docker-php-source extract \
    && curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis \
    && docker-php-ext-install redis \
    && docker-php-source delete

# apcu
RUN docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && apk del .phpize-deps-configure \
    && docker-php-source delete


# xdebug
RUN docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .phpize-deps-configure \
    && docker-php-source delete

# git client
RUN apk add --update --no-cache git

# imagick
RUN apk add --update --no-cache autoconf g++ imagemagick-dev libtool make \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apk del autoconf g++ libtool make


RUN sed -i -e 's/listen.*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.conf

RUN echo "expose_php=0" > /usr/local/etc/php/php.ini

RUN echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/memory-limit.ini

RUN echo "date.timezone=${PHP_TIMEZONE:-UTC}" > $PHP_INI_DIR/conf.d/date_timezone.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 

ENV COMPOSER_ALLOW_SUPERUSER 1

# Install Code Sniffer
RUN pear install PHP_CodeSniffer

RUN phpcs --config-set colors 1
RUN phpcs --config-set default_standard PSR2
RUN phpcs --config-set severity 1
RUN phpcs --config-set report_width 120

RUN rm -rf /var/cache/apk/*

CMD ["php-fpm"]
