# Pull base image
FROM arm32v7/alpine:3.12

# Label for Information about this Image.
LABEL org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
	org.opencontainers.image.title="alpine-nginx-php" \
	org.opencontainers.image.description="AlpineLinux with NGINX Webserver and PHP7 on arm arch" \
	org.opencontainers.image.licenses="Apache-2.0" \
	org.opencontainers.image.url="https://hub.docker.com/r/tobi312/alpine-nginx-php" \
	org.opencontainers.image.source="https://github.com/Tob1asDocker/alpine-nginx-php"

# Define variable
ENV LANG C.UTF-8
ENV TERM=xterm
ENV WWW_USER=www-data

# Install
RUN set -eux &&  \
	addgroup -g 82 -S $WWW_USER && adduser -u 82 -D -S -h /var/cache/$WWW_USER -s /sbin/nologin -G $WWW_USER $WWW_USER && \
	# 82 is the standard uid/gid for "www-data" in Alpine
	# https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install
	apk --no-cache add \
		tzdata \
		#git wget curl nano zip unzip \
		supervisor \
		nginx \
		php7 php7-common php7-fpm php7-opcache \
	&& mkdir -p /run/nginx \
	&& mkdir -p /etc/ssl/nginx \
	&& mkdir -p /var/www/html \ 
	&& chown -R $WWW_USER:$WWW_USER /var/www/html \
	#&& chown -R $WWW_USER:$WWW_USER /var/tmp/nginx \
	&& sed -i "s/ssl_session_cache shared:SSL:2m;/#ssl_session_cache shared:SSL:2m;/g" /etc/nginx/nginx.conf \
	&& sed -i "s/user nginx;/user ${WWW_USER};/g" /etc/nginx/nginx.conf \
	#&& sed -i "s/client_max_body_size 1m;/client_max_body_size 0;/g" /etc/nginx/nginx.conf \
	&& sed -i "s|;listen.mode\s*=\s*0660|listen.mode = 0660}|g" /etc/php7/php-fpm.d/www.conf \
	&& sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${WWW_USER}|g" /etc/php7/php-fpm.d/www.conf \
	&& sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${WWW_USER}|g" /etc/php7/php-fpm.d/www.conf \
	&& sed -i "s|user\s*=\s*nobody|user = ${WWW_USER}|g" /etc/php7/php-fpm.d/www.conf \
	&& sed -i "s|group\s*=\s*nobody|group = ${WWW_USER}|g" /etc/php7/php-fpm.d/www.conf \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& ln -sf /dev/stderr /var/log/php7/error.log \
	&& mkdir /entrypoint.d

# Copy files and folders into image
COPY config/nginx_default.conf /etc/nginx/conf.d/default.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#COPY source /var/www/html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Define workdir
WORKDIR /var/www/html

# Define mountable directories
VOLUME ["/etc/nginx/conf.d/","/etc/ssl/nginx","/var/www/html"]

# Expose ports
EXPOSE 80 443

# Define main command
ENTRYPOINT ["/entrypoint.sh"]

# Define default command
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
