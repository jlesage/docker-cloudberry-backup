#
# clouberry-backup Dockerfile
#
# https://github.com/jlesage/docker-cloudberry-backup
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG CLOUDBERRYBACKUP_VERSION=3.3.2.22
ARG CLOUDBERRYBACKUP_TIMESTAMP=20220127175903

# Define software download URLs.
ARG CLOUDBERRYBACKUP_URL=https://d1jra2eqc0c15l.cloudfront.net/ubuntu14_CloudBerryLab_CloudBerryBackup_v${CLOUDBERRYBACKUP_VERSION}_${CLOUDBERRYBACKUP_TIMESTAMP}.deb

# Build CloudBerry Backup.
FROM ubuntu:20.04 AS cbb
ARG CLOUDBERRYBACKUP_URL
COPY src/cloudberry-backup/build.sh /build-cloudberry-backup.sh
RUN /build-cloudberry-backup.sh "$CLOUDBERRYBACKUP_URL"

# Build YAD.
FROM alpine:3.14 AS yad
COPY src/yad/build.sh /build-yad.sh
RUN /build-yad.sh

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12-v3.5.8
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install CloudBerry Backup.
COPY --from=cbb ["/opt/local/CloudBerry Backup", "/opt/local/CloudBerry Backup"]
COPY --from=cbb ["/opt/local/Online Backup", "/defaults/Online Backup"]
COPY --from=cbb /usr/lib/x86_64-linux-gnu/gconv /usr/lib/x86_64-linux-gnu/gconv
COPY --from=cbb /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive
RUN \
    # Setup symbolic links for stuff that need to be outside the container.
    ln -s /config/"Online Backup" /opt/local/"Online Backup" && \
    # Fix PAM authentication for web interface.
    ln -s base-auth /etc/pam.d/common-auth

# Install YAD.
COPY --from=yad /tmp/yad-install/usr/bin/yad /usr/bin/

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" class="cbbGUI" title="CloudBerry Backup">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" class="cbbGUI" title="CloudBerry Backup">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Install dependencies.
RUN \
    add-pkg \
        mkpasswd

# Enable log monitoring.
RUN \
    sed-patch 's|STATUS_FILES=|STATUS_FILES=/tmp/.upgrade_performed|' /etc/logmonitor/logmonitor.conf && \
    # The following change should be done in the baseimage.
    sed-patch 's|> /dev/null|> /dev/null 2>\&1|' /etc/logmonitor/targets.d/yad/send && \
    sed-patch 's/yad --version |/yad --version 2>\/dev\/null |/' /etc/logmonitor/targets.d/yad/send

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/cloudberry-backup-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="CloudBerry Backup" \
    CBB_WEB_INTERFACE_USER="" \
    CBB_WEB_INTERFACE_PASSWORD=""

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Expose ports.
#   - 43210: CloudBerry Backup web interface (HTTP).
#   - 43211: CloudBerry Backup web interface (HTTPs).
EXPOSE 43210 43211

# Metadata.
LABEL \
      org.label-schema.name="cloudberry-backup" \
      org.label-schema.description="Docker container for CloudBerry Backup" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-cloudberry-backup" \
      org.label-schema.schema-version="1.0"
