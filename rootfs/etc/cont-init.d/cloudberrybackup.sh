#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Copy default config if needed.
if [ ! -d /config/etc ]
then
    echo "CloudBerry Backup config not found, copying default one..."
    cp -pr /opt/local/"CloudBerry Backup"/etc.default /config/etc
    /opt/local/"CloudBerry Backup"/bin/cbbUpdater
fi

# Generate HID if needed
if [ ! -f /config/HID ]
then
    echo "Generating HID..."
    cat /proc/sys/kernel/random/uuid > /config/HID
fi

# Check if an upgrade is needed.
CUR_VERSION="$(cat /opt/local/"CloudBerry Backup"/etc/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
NEW_VERSION="$(cat /opt/local/"CloudBerry Backup"/etc.default/config/cloudBackup.conf | grep -w buildVersion | cut -d ':' -f2 | tr -d ' ')"
if [ "$CUR_VERSION" != "$NEW_VERSION" ]; then
    echo "Upgrading CloudBerry Backup from version $CUR_VERSION to $NEW_VERSION..."
    cp /opt/local/"CloudBerry Backup"/etc.default/config/cloudBackup.conf /config/etc/config/cloudBackup.conf
    /opt/local/"CloudBerry Backup"/bin/cbbUpdater
fi

# Make sure default directories exist.
mkdir -p /config/logs

# Adjust config file permissions.
chown -R $USER_ID:$GROUP_ID /config

# vim: set ft=sh :
