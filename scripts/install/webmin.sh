#! /bin/bash
# shellcheck disable=SC2024
# Webmin installer
# flying_sausages for swizzin 2020

_install_webmin() {
    echo_progress_start "Installing Webmin repo"
    echo "deb [signed-by=/usr/share/keyrings/debian-webmin-developers.gpg] https://download.webmin.com/download/newkey/repository stable contrib" > /etc/apt/sources.list.d/webmin.list
    curl -s https://download.webmin.com/developers-key.asc | gpg --dearmor > /usr/share/keyrings/debian-webmin-developers.gpg 2>> "${log}"
    echo_progress_done "Repo added"
    apt_update
    apt_install webmin
}

_install_webmin
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /etc/swizzin/scripts/nginx/webmin.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Webmin will run on port 10000"
fi

echo_success "Webmin installed"
echo_info "Please use any account with sudo permissions to log in"

touch /install/.webmin.lock
