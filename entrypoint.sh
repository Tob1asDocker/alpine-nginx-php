#!/bin/sh
set -eu

## Variables
## https://stackoverflow.com/a/32343069/3441436
: "${TZ:=""}"                                 # set timezone, example: "Europe/Berlin"
: "${PHP_ERRORS:="0"}"                        # set 1 to enable
: "${PHP_STARTUP_ERRORS:="0"}"                # set 1 to enable
: "${PHP_MEM_LIMIT:=""}"                      # set Value in MB, example: 128
: "${PHP_POST_MAX_SIZE:=""}"                  # set Value in MB, example: 250
: "${PHP_UPLOAD_MAX_FILESIZE:=""}"            # set Value in MB, example: 250
: "${PHP_MAX_FILE_UPLOADS:=""}"               # set number, example: 20
: "${CREATE_PHPINFO_FILE:="0"}"               # set 1 to enable

## Set TimeZone
if [ ! -z "$TZ" ]; then
	echo ">> set timezone"
	cp /usr/share/zoneinfo/${TZ} /etc/localtime
	echo ${TZ} > /etc/timezone
	date
	sed -i "s|;*date.timezone =.*|date.timezone = ${TZ}|i" /etc/php7/php.ini
fi

## display PHP error's
if [[ "$PHP_ERRORS" == "1" ]] ; then
	echo ">> set display_errors"
	sed -i "s|display_errors\s*=\s*Off|display_errors = On|i" /etc/php7/php.ini
fi

## display startup PHP error's
if [[ "$PHP_STARTUP_ERRORS" == "1" ]] ; then
	echo ">> set display_startup_errors"
	sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = On|i" /etc/php7/php.ini
fi

## changes the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
	echo ">> set memory_limit"
	sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEM_LIMIT}M|i" /etc/php7/php.ini
fi

## changes the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
	echo ">> set post_max_size"
	sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_POST_MAX_SIZE}M|i" /etc/php7/php.ini
fi

## changes the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
	echo ">> set upload_max_filesize"
	sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}M|i" /etc/php7/php.ini
fi

## changes the max_file_uploads
if [ ! -z "$PHP_MAX_FILE_UPLOADS" ]; then
	echo ">> set max_file_uploads"
	sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOADS}|i" /etc/php7/php.ini
fi

## create phpinfo-file (for dev and testing)
if [ "$CREATE_PHPINFO_FILE" -eq "1" -a ! -e "/var/www/html/phpinfo.php" ]; then
	echo ">> create phpinfo-file"
	echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
fi

## more entrypoint-files
find "/entrypoint.d/" -follow -type f -print | sort -n | while read -r f; do
	case "$f" in
		*.sh)
			if [ ! -x "$f" ] ; then 
				echo ">> $f is not executable!"
				chmod +x $f
			fi
			echo ">> $f is executed!"
			/bin/sh $f
			;;
		*)  echo ">> $f is no *.sh-file!" ;;
	esac
done

# exec CMD
echo ">> exec docker CMD"
echo "$@"
exec "$@"
