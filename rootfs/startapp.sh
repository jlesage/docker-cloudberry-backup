#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

cd /config
exec /opt/local/"CloudBerry Backup"/bin/cbbGUI

# vim: set ft=sh :
