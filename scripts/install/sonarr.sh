#!/bin/bash
# Sonarr Installer
# GPLv3 applies

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

app_name="sonarr"
if [ -z "$SONARR_OWNER" ]; then
    if ! SONARR_OWNER="$(swizdb get "$app_name/owner")"; then
        SONARR_OWNER="$(_get_master_username)"
        swizdb set "$app_name/owner" "$SONARR_OWNER"
    fi
else
    echo_info "Setting ${app_name^} owner = $SONARR_OWNER"
    swizdb set "$app_name/owner" "$SONARR_OWNER"
fi

user="$SONARR_OWNER"
swiz_configdir="/home/$user/.config"
app_configdir="$swiz_configdir/${app_name^}"
app_group="$user"
app_port="8989"
app_reqs=("curl" "sqlite3")
app_servicefile="$app_name.service"
app_dir="/opt/${app_name^}"
app_binary="${app_name^}"
app_lockname="${app_name//-/}"
app_branch="develop" # Change to stable when available, tell users to migrate manually.

if [ ! -d "$swiz_configdir" ]; then
    mkdir -p "$swiz_configdir"
fi
chown "$user":"$user" "$swiz_configdir"

_install() {
    if [ ! -d "$app_configdir" ]; then
        mkdir -p "$app_configdir"
    fi
    chown -R "$user":"$user" "$app_configdir"

    apt_install "${app_reqs[@]}"

    echo_progress_start "Downloading release archive"

    urlbase="https://services.sonarr.tv/v1/download/develop/latest?version=4&os=linux"
    case "$(_os_arch)" in
        "amd64") dlurl="${urlbase}&arch=x64" ;;
        "armhf") dlurl="${urlbase}&arch=arm" ;;
        "arm64") dlurl="${urlbase}&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o "/tmp/$app_name.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"
    tar xfv "/tmp/$app_name.tar.gz" --directory /opt/ >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/$app_name.tar.gz"
    chown -R "${user}": "$app_dir"
    echo_progress_done "Archive extracted"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/"$app_name".sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "$app_name will run on port $app_port"
    fi
}

_systemd() {

    echo_progress_start "Installing Systemd service"
    cat > "/etc/systemd/system/$app_servicefile" << EOF
[Unit]
Description=${app_name^} Daemon
After=syslog.target network.target
[Service]
# Change the user and group variables here.
User=${user}
Group=${app_group}
Type=simple
# Change the path to ${app_name^} here if it is in a different location for you.
ExecStart=$app_dir/$app_binary -nobrowser -data=$app_configdir
TimeoutStopSec=20
KillMode=process
Restart=on-failure
# These lines optionally isolate (sandbox) ${app_name^} from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=$app_dir /path/to/media/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true
[Install]
WantedBy=multi-user.target
EOF

    systemctl -q daemon-reload
    systemctl enable --now -q "$app_servicefile"
    sleep 1
    echo_progress_done "${app_name^} service installed and enabled"
    # In theory there should be no updating needed, so let's generalize this
    echo_progress_start "${app_name^} is loading..."
    if ! timeout 30 bash -c -- "while ! curl -sIL http://127.0.0.1:$app_port >> \"$log\" 2>&1; do sleep 2; done"; then
        echo_error "The ${app_name^} web server has taken longer than 30 seconds to start."
        exit 1
    fi
    echo_progress_done "Loading finished"
}

_install
_systemd
_nginx

touch "/install/.$app_lockname.lock"
echo_success "${app_name^} installed"