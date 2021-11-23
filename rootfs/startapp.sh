#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

#export QT_DEBUG_PLUGINS=1

cd /config
exec /opt/local/"CloudBerry Backup"/bin/cbbGUI

# vim: set ft=sh :
