FROM php:7.1.3-fpm-alpine

# php-redis
ENV PHPREDIS_VERSION 3.0.0

RUN docker-php-source extract \
    && curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis \
    && docker-php-ext-install redis \
    && docker-php-source delete \
    # xdebug
    && docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .phpize-deps-configure \
    && docker-php-source delete \
    && apk add --update --no-cache autoconf g++ imagemagick-dev libtool make \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apk del autoconf g++ libtool make \
    && apk add --update --no-cache \
        freetype-dev \
        libpng-dev libjpeg-turbo-dev \
        libmcrypt-dev \
		libintl icu icu-dev libxml2-dev \
	&& docker-php-ext-install intl zip soap pdo pdo_mysql opcache \
    && docker-php-ext-configure gd \
		--enable-gd-native-ttf \
		--with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd iconv mcrypt bcmath \
    && echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    && echo "@community http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    && apk add --no-cache pdftk@community libgcj@edge

COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

ADD ./innolend.ini /usr/local/etc/php/conf.d
ADD ./innolend.pool.conf /usr/local/etc/php-fpm.d/

RUN if [ ${PHP_TIMEZONE} ]; then \
	echo "date.timezone=${PHP_TIMEZONE}" > $PHP_INI_DIR/conf.d/date_timezone.ini \
;fi
	
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 

ENV COMPOSER_ALLOW_SUPERUSER 1

# Install Code Sniffer
RUN composer global require "squizlabs/php_codesniffer=*"

RUN rm -rf /var/cache/apk/*

CMD ["php-fpm"]
