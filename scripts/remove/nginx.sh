#!/bin/bash

systemctl stop -q nginx
[[ $(_os_codename) =~ ^(focal|buster|bullseye)$ ]] && geoip="php8.2-geoip" || geoip=""
APT="nginx libnginx-mod-http-fancyindex subversion ssl-cert libfcgi0ldbl php8.2-fpm php8.2-cli php8.2-dev php8.2-xml php8.2-curl php8.2-xmlrpc php8.2-mbstring php8.2-opcache php8.2-zip ${geoip} ${mcrypt}"
apt_remove $APT

LIST='nginx-* php8.2-* php-*'
apt_remove --purge $LIST

rm -rf /etc/nginx
rm -rf /etc/php

. /etc/swizzin/sources/functions/utils
rm_if_exists "/srv/rutorrent"
rm_if_exists "/install/.rutorrent.lock"

rm_if_exists "/srv/panel"
rm_if_exists "/etc/sudoers.d/panel"
rm_if_exists "/etc/cron.d/set_interface"

# rm_if_exists "/srv/organizr"
rm_if_exists "/install/.organizr.lock"

rm /install/.nginx.lock
