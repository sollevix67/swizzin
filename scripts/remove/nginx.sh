#!/bin/bash

systemctl stop -q nginx
[[ $(_os_codename) =~ ^(focal|buster|bullseye|noble)$ ]] && geoip= || geoip=
APT="nginx libnginx-mod-http-fancyindex subversion ssl-cert libfcgi0ldbl php8.3-fpm php8.3-cli php8.3-dev php8.3-xml php8.3-curl php8.3-xmlrpc php8.3-mbstring php8.3-opcache php8.3-zip ${geoip} ${mcrypt}"
apt_remove $APT

LIST='nginx-* php8.3-* php-*'
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
