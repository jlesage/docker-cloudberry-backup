#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

# Generate machine id
log "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Copy default config if needed.
if [ ! -d /config/etc ]
then
    log "CloudBerry Backup config not found, copying default one..."
    cp -pr /defaults/cbb_etc /config/etc
    /opt/local/"CloudBerry Backup"/bin/cbbUpdater
fi

# Generate HID if needed
if [ ! -f /config/HID ]
then
    log "Generating HID..."
    cat /proc/sys/kernel/random/uuid > /config/HID
fi

# Check if a configuration upgrade is needed.
CUR_VERSION="$(cat /opt/local/"CloudBerry Backup"/etc/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
NEW_VERSION="$(cat /defaults/cbb_etc/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
if [ "$CUR_VERSION" != "$NEW_VERSION" ]; then
    log "Upgrading CloudBerry Backup configuration from version $CUR_VERSION to $NEW_VERSION..."
    cp /defaults/cbb_etc/config/cloudBackup.conf /config/etc/config/cloudBackup.conf
    cp /defaults/cbb_etc/config/wt_config.xml /config/etc/config/wt_config.xml
    /opt/local/"CloudBerry Backup"/bin/cbbUpdater
fi

# Convert CloudBerry web interface's clear-text password to password hash.
if [ -f /config/.cbb_web_interface_clear_text_pass ]; then
    cat /config/.cbb_web_interface_clear_text_pass | mkpasswd -m sha-512 -P 0 > /config/.cbb_web_interface_pass_hash
    rm /config/.cbb_web_interface_clear_text_pass
    log "Converted CloudBerry web interface's clear-text password to password hash."
fi

# Handle password for CloudBerry web interface.
if [ "${CBB_WEB_INTERFACE_USER:-UNSET}" = "UNSET" ]; then
    log "CloudBerry Backup web interface not usable: No user name defined."
elif id "$CBB_WEB_INTERFACE_USER" >/dev/null 2>&1; then
    log "CloudBerry Backup web interface not usable: User name '$CBB_WEB_INTERFACE_USER' is reserved."
else
    if [ -f /config/.cbb_web_interface_pass_hash ]; then
        PASS="$(cat /config/.cbb_web_interface_pass_hash)"
    elif [ "${CBB_WEB_INTERFACE_PASSWORD:-UNSET}" != "UNSET" ]; then
        PASS="$(echo "$CBB_WEB_INTERFACE_PASSWORD" | mkpasswd -m sha-512 -P 0)"
    else
        PASS=UNSET
    fi

    # Create a Linux user matching credentials.
    if [ "$PASS" != "UNSET" ]; then
        useradd --system \
                --no-create-home \
                --no-user-group \
                --shell /sbin/nologin \
                --home-dir /dev/null \
                --password "$PASS" \
                $CBB_WEB_INTERFACE_USER
    else
        log "CloudBerry Backup web interface not usable: No password defined."
    fi
fi

# Make sure default directories exist.
mkdir -p /config/logs

# Take ownership of the config directory content.
chown -R $USER_ID:$GROUP_ID /config/*

# vim: set ft=sh :
