#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

OWNER_ID="00000000-0000-0000-0000-000000000000"

# Make sure default directories exist.
mkdir -p /config/etc
mkdir -p /config/logs
mkdir -p /config/"Online Backup"


# Generate machine id
if [ ! -f /etc/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi

# Check if default etc files need to be copied.  This should be done in two
# cases:
#   - On initial startup.
#   - On upgrade.
COPY_DEFAULT_ETC=0
NEW_VERSION="$(cat /defaults/cbb_etc/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
if [ ! -d /opt/local/"Online Backup"/"$OWNER_ID" ]
then
    if [ -f /opt/local/"CloudBerry Backup"/etc/config/cloudBackup.conf ]; then
        CUR_VERSION="$(cat /opt/local/"CloudBerry Backup"/etc/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
        log "Upgrading CloudBerry Backup configuration from version $CUR_VERSION to $NEW_VERSION..."
    else
        log "CloudBerry Backup config not found, copying default one..."
    fi
    COPY_DEFAULT_ETC=1

    # Location of HID changed.  Make sure to move it.
    if [ -f /config/HID ]; then
        # During upgrade, CBB expects the HID to be at the old location and
        # it must be able to move the file to the new location.
        mv /config/HID /opt/local/"CloudBerry Backup"/share/
        chmod a+w /opt/local/"CloudBerry Backup"/share
    fi
else
    CUR_VERSION="$(cat /opt/local/"Online Backup"/"$OWNER_ID"/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
    if [ "$CUR_VERSION" != "$NEW_VERSION" ]; then
        log "Upgrading CloudBerry Backup configuration from version $CUR_VERSION to $NEW_VERSION..."
        COPY_DEFAULT_ETC=1
    fi
fi


# Copy etc files to /opt/local/CloudBerry Backup/etc (symlink to /config/etc).
# CBB will then move them under /opt/local/Online Backup/.
if [ "$COPY_DEFAULT_ETC" -eq 1 ]; then
    cp -pr /defaults/cbb_etc/* /opt/local/"CloudBerry Backup"/etc/
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

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :
