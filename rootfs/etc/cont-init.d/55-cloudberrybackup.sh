#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "$*"
}

OWNER_ID="00000000-0000-0000-0000-000000000000"

# Make sure default directories exist.
mkdir -p /config/etc
mkdir -p /config/"Online Backup"

# Generate machine id
if [ ! -f /config/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi

# Handle initial start and upgrade scenarios.
NEW_VERSION="$(cat /defaults/"Online Backup"/"$OWNER_ID"/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
if [ ! -d /opt/local/"Online Backup"/"$OWNER_ID" ]
then
    # No existing config found.

    if [ -f /opt/local/"CloudBerry Backup"/etc/config/cloudBackup.conf ]; then
        # We are upgrading from an old version.
        CUR_VERSION="$(cat /opt/local/"CloudBerry Backup"/etc/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
        log "Upgrading CloudBerry Backup configuration from version $CUR_VERSION to $NEW_VERSION..."
        cp -pr /defaults/"Online Backup"/* /config/"Online Backup"/
        su-exec app touch /tmp/.upgrade_performed
    else
        # We are starting for the first time.
        log "CloudBerry Backup config not found, copying default one..."
        cp -pr /defaults/"Online Backup"/* /config/"Online Backup"/
    fi

    # Location of HID changed.  Make sure to move it.
    if [ -f /config/HID ]; then
        # During upgrade, CBB expects the HID to be at the old location and
        # it must be able to move the file to the new location.
        mv /config/HID /opt/local/"CloudBerry Backup"/share/
        chmod a+w /opt/local/"CloudBerry Backup"/share
    fi

    /opt/local/"CloudBerry Backup"/bin/cbbUpdater
else
    # Existing config found.  Check if CloudBerry Backup version changed.
    CUR_VERSION="$(cat /opt/local/"Online Backup"/"$OWNER_ID"/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
    if [ "$CUR_VERSION" != "$NEW_VERSION" ]; then
        log "Upgrading CloudBerry Backup configuration from version $CUR_VERSION to $NEW_VERSION..."
        su-exec app touch /tmp/.upgrade_performed

        # Some files are replaced during normal upgrade.  These are the ones
        # under /opt/local/CloudBerry Backup/etc/config/ from the .deb package.
        for FILE in cloudBackup.conf wt_config.xml
        do
            cp /defaults/"Online Backup"/"$OWNER_ID"/config/$FILE /opt/local/"Online Backup"/"$OWNER_ID"/config/
        done

        /opt/local/"CloudBerry Backup"/bin/cbbUpdater
    fi
fi

# Convert CloudBerry web interface's clear-text password to password hash.
if [ -f /config/.cbb_web_interface_clear_text_pass ]; then
    cat /config/.cbb_web_interface_clear_text_pass | mkpasswd -m sha-512 -P 0 > /config/.cbb_web_interface_pass_hash
    rm /config/.cbb_web_interface_clear_text_pass
    log "Converted CloudBerry web interface's clear-text password to password hash."
fi

# Handle password for CloudBerry web interface.
if [ "${CBB_WEB_INTERFACE_USER:-UNSET}" = "UNSET" ]; then
    log "CloudBerry Backup web interface disabled: No user name defined."
elif id "$CBB_WEB_INTERFACE_USER" >/dev/null 2>&1; then
    log "CloudBerry Backup web interface disabled: User name '$CBB_WEB_INTERFACE_USER' is reserved."
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
        su-exec app touch /tmp/.cbb_web_interface_enabled
    else
        log "CloudBerry Backup web interface disabled: No password defined."
    fi
fi

# vim: set ft=sh :
