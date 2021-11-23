#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

if [ -z "${1:-}" ]; then
    echo "ERROR: CloudBerry Backup URL not provided."
    exit 1
fi

CLOUDBERRYBACKUP_URL="$1"

apt update
apt upgrade -y
apt install -y --no-install-recommends \
    wget \
    ca-certificates \
    patchelf \
    libgl1 \
    libxrender1 \
    libxcursor1 \
    libdbus-1-3

# Download CloudBerry Backup.
wget "$CLOUDBERRYBACKUP_URL" -O /tmp/cbb.deb

# Install CloudBerry Backup.
dpkg --force-all --install /tmp/cbb.deb

service cloudberry-backup stop
service cloudberry-backupWA stop

rm /opt/local/"Online Backup"/00000000-0000-0000-0000-000000000000/logs/*
rm /opt/local/"Online Backup"/00000000-0000-0000-0000-000000000000/config/HID

# Replace libudev.so.0 packaged with CloudBerry Backup, which causes an error
# when loading the QT xcb plugin.
rm /opt/local/"CloudBerry Backup"/lib/libudev.so.0
cp $(find /lib/x86_64-linux-gnu/ -type f -name "libudev.so*") /opt/local/"CloudBerry Backup"/lib/libudev.so.0

# Modify installed scripts to use sh instead of bash.
find /opt/local/"CloudBerry Backup"/bin/ -type f -exec sed 's/^#!\/bin\/bash/#!\/bin\/sh/' -i {} ';'

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

echo "Copying extra libraries..."
for LIB in $EXTRA_LIBS
do
    cp -av "$LIB"* /opt/local/"CloudBerry Backup"/lib/
done

# Extract dependencies of all binaries and libraries.
echo "Extracting shared library dependencies..."
find /opt/local/"CloudBerry Backup"/raw_bin /opt/local/"CloudBerry Backup"/lib -type f -executable -or -name 'lib*.so*' | while read BIN
do
    RAW_DEPS="$(LD_LIBRARY_PATH="/opt/local/CloudBerry Backup/lib" ldd "$BIN")"
    echo "Dependencies for $BIN:"
    echo "================================"
    echo "$RAW_DEPS"
    echo "================================"

    if echo "$RAW_DEPS" | grep -q " not found"; then
        echo "ERROR: Some libraries are missing!"
        exit 1
    fi

    LD_LIBRARY_PATH="/opt/local/CloudBerry Backup/lib" ldd "$BIN" | (grep " => " || true) | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1 | while read dep
    do
        dep_real="$(realpath "$dep")"
        dep_basename="$(basename "$dep_real")"

        # Skip already-processed libraries.
        [ ! -f "/opt/local/CloudBerry Backup/lib/$dep_basename" ] || continue

        echo "  -> Found library: $dep"
        cp "$dep_real" "/opt/local/CloudBerry Backup/lib/"
        while true; do
            [ -L "$dep" ] || break;
            ln -sf "$dep_basename" "/opt/local/CloudBerry Backup"/lib/$(basename $dep)
            dep="$(readlink -f "$dep")"
        done
    done
done

echo "Patching ELF of binaries..."
find "/opt/local/CloudBerry Backup/raw_bin" -type f -executable -exec echo "  -> Setting interpreter of {}..." ';' -exec patchelf --set-interpreter "/opt/local/CloudBerry Backup/lib/ld-linux-x86-64.so.2" {} ';'
find "/opt/local/CloudBerry Backup/raw_bin" -type f -executable -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN/../lib' {} ';'

echo "Patching ELF of libraries..."
find "/opt/local/CloudBerry Backup/lib" -type f -name "lib*" -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN' {} ';'

echo "Copying interpreter..."
cp -av /lib/x86_64-linux-gnu/ld-* "/opt/local/CloudBerry Backup/lib/"
