FROM php:7.0-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Download and install tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    libmcrypt-dev \
    unzip libzip-dev \
    ca-certificates \
    git \
    mongodb-server \
    nginx \
    supervisor && \
    # Clone xhgui then remove useless files
    git clone https://github.com/perftools/xhgui /usr/local/src/xhgui && \
    cd /usr/local/src/xhgui && \
    rm -Rf /usr/local/src/xhgui/.git \
           /usr/local/src/xhgui/.scrutinizer.yml \
           /usr/local/src/xhgui/.travis.yml \
           /usr/local/src/xhgui/phpunit.xml \
           /usr/local/src/xhgui/README.md \
           /usr/local/src/xhgui/tests && \
    # Clean
    apt-get purge git -y  && \
    rm -rf /var/lib/apt/lists/*

# Install php extensions
RUN docker-php-ext-install -j$(nproc) mcrypt && \
    pecl install mongodb && docker-php-ext-enable mongodb && \
    pecl install zip && docker-php-ext-enable zip

# Add xhgui config
COPY conf/xhgui.config.php /usr/local/src/xhgui/config/config.php

# Install xhgui
RUN cd /usr/local/src/xhgui && \
    php install.php && \
    chown -R www-data:www-data /usr/local/src/xhgui && \
    rm -f composer.phar

# Prepare Mongodb
RUN mkdir -p /data/db /var/log/mongodb && \
    chown -R mongodb:mongodb /data /var/log/mongodb

# Prepare nginx
COPY conf/nginx.default.conf /etc/nginx/sites-available/default
RUN mkdir -p /var/log/nginx /var/log/php && \
    chown -R www-data:www-data /var/log/nginx

# Supervisord
RUN mkdir -p /var/log/supervisor
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Global directives
VOLUME ["/data/db"]
WORKDIR /usr/local/src/xhgui

EXPOSE 80 27017

COPY post-run.sh /root/post-run.sh
RUN chmod +x /root/post-run.sh

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
