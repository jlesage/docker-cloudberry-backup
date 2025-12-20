#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
    echo ">>> $*"
}

if [ -z "${1:-}" ]; then
    echo "ERROR: CloudBerry Backup URL not provided."
    exit 1
fi

CLOUDBERRYBACKUP_URL="$1"

log "Updating APT cache..."
apt update

log "Installing build prerequisites..."
apt upgrade -y
apt install -y --no-install-recommends \
    locales \
    wget \
    ca-certificates \
    patchelf \
    libgl1 \
    libxrender1 \
    libxcursor1 \
    libdbus-1-3 \

# Generate locale.
locale-gen en_US.UTF-8

# Download CloudBerry Backup.
log "Downloading CloudBerry Backup..."
wget "$CLOUDBERRYBACKUP_URL" -O /tmp/cbb.deb

# Install CloudBerry Backup.
log "Installing CloudBerry Backup..."
dpkg --force-all --install /tmp/cbb.deb

service msp360-backup stop
service msp360-backupWA stop

rm /opt/local/"Online Backup"/00000000-0000-0000-0000-000000000000/logs/*
rm /opt/local/"Online Backup"/00000000-0000-0000-0000-000000000000/config/HID

# Replace libudev.so.0 packaged with CloudBerry Backup, which causes an error
# when loading the QT xcb plugin.
rm /opt/local/"MSP360 Backup"/lib/libudev.so.0
cp $(find /lib/x86_64-linux-gnu/ -type f -name "libudev.so*") /opt/local/"MSP360 Backup"/lib/libudev.so.0

# Modify installed scripts to use sh instead of bash.
find /opt/local/"MSP360 Backup"/bin/ -type f -exec sed 's/^#!\/bin\/bash/#!\/bin\/sh/' -i {} ';'

# Extra libraries that need to be installed into the CloudBerry Backup lib
# folder.  These libraries are loaded dynamically (dlopen) and are not catched
# by tracking dependencies.
EXTRA_LIBS="
    /lib/x86_64-linux-gnu/libnss_dns
    /lib/x86_64-linux-gnu/libnss_files
    /lib/x86_64-linux-gnu/libdbus-1.so.3
    /usr/lib/x86_64-linux-gnu/libXfixes.so.3
    /usr/lib/x86_64-linux-gnu/libXrender.so.1
    /usr/lib/x86_64-linux-gnu/libXcursor.so.1
"

log "Copying extra libraries..."
for LIB in $EXTRA_LIBS
do
    cp -av "$LIB"* /opt/local/"MSP360 Backup"/lib/
done

# Extract dependencies of all binaries and libraries.
log "Extracting shared library dependencies..."
find /opt/local/"MSP360 Backup"/raw_bin /opt/local/"MSP360 Backup"/lib -type f -executable -or -name 'lib*.so*' -or -name '*.so' | while read BIN
do
    RAW_DEPS="$(LD_LIBRARY_PATH="/opt/local/MSP360 Backup/lib" ldd "$BIN")"
    echo "Dependencies for $BIN:"
    echo "================================"
    echo "$RAW_DEPS"
    echo "================================"

    if echo "$RAW_DEPS" | grep -q " not found"; then
        echo "ERROR: Some libraries are missing!"
        exit 1
    fi

    LD_LIBRARY_PATH="/opt/local/MSP360 Backup/lib" ldd "$BIN" | (grep " => " || true) | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1 | while read dep
    do
        dep_real="$(realpath "$dep")"
        dep_basename="$(basename "$dep_real")"

        # Skip already-processed libraries.
        [ ! -f "/opt/local/MSP360 Backup/lib/$dep_basename" ] || continue

        echo "  -> Found library: $dep"
        cp "$dep_real" "/opt/local/MSP360 Backup/lib/"
        while true; do
            [ -L "$dep" ] || break;
            ln -sf "$dep_basename" "/opt/local/MSP360 Backup"/lib/$(basename $dep)
            dep="$(readlink -f "$dep")"
        done
    done
done

log "Patching ELF of binaries..."
find "/opt/local/MSP360 Backup/raw_bin" -type f -executable -exec echo "  -> Setting interpreter of {}..." ';' -exec patchelf --set-interpreter "/opt/local/MSP360 Backup/lib/ld-linux-x86-64.so.2" {} ';'
find "/opt/local/MSP360 Backup/raw_bin" -type f -executable -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN/../lib' {} ';'

log "Patching ELF of libraries..."
find "/opt/local/MSP360 Backup/lib" -type f -name "lib*" -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN' {} ';'

log "Copying interpreter..."
cp -av /lib/x86_64-linux-gnu/ld-* "/opt/local/MSP360 Backup/lib/"

log "CloudBerry backup build successfully."
