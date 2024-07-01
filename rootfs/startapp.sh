#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

#export QT_DEBUG_PLUGINS=1

PIDS=

notify() {
    for N in $(ls /etc/logmonitor/targets.d/*/send)
    do
       timeout 1800 "$N" "$1" "$2" "$3" &
       PIDS="$PIDS $!"
    done
}

# Verify if CloudBerry Backup has been upgraded.
if  [ -f /tmp/.upgrade_performed ]; then
   notify "$APP_NAME upgraded." "$APP_NAME has been upgraded.  The upgrade can take several minutes to complete.  During this time, the UI might only show a black screen." "INFO"
   rm /tmp/.upgrade_performed
fi

# Wait for all PIDs to terminate.
set +e
for PID in "$PIDS"; do
   wait $PID
done
set -e

cd /config
exec /opt/local/"MSP360 Backup"/bin/cbbGUI

# vim:ft=sh:ts=4:sw=4:et:sts=4
