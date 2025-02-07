#
# clouberry-backup Dockerfile
#
# https://github.com/jlesage/docker-cloudberry-backup
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG CLOUDBERRYBACKUP_VERSION=4.3.3.255
ARG CLOUDBERRYBACKUP_TIMESTAMP=20250107173119

# Define software download URLs.
ARG CLOUDBERRYBACKUP_URL=https://download.msp360.com/ubuntu14_MSP360_MSP360Backup_v${CLOUDBERRYBACKUP_VERSION}_${CLOUDBERRYBACKUP_TIMESTAMP}.deb

# Build CloudBerry Backup.
FROM ubuntu:20.04 AS cbb
ARG CLOUDBERRYBACKUP_URL
COPY src/cloudberry-backup/build.sh /build-cloudberry-backup.sh
RUN /build-cloudberry-backup.sh "$CLOUDBERRYBACKUP_URL"

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.16-v4.7.1

ARG CLOUDBERRYBACKUP_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install CloudBerry Backup.
COPY --from=cbb ["/opt/local/MSP360 Backup", "/opt/local/MSP360 Backup"]
COPY --from=cbb ["/opt/local/Online Backup", "/defaults/Online Backup"]
COPY --from=cbb /usr/lib/x86_64-linux-gnu/gconv /usr/lib/x86_64-linux-gnu/gconv
COPY --from=cbb /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive
RUN \
    # Setup symbolic links for stuff that need to be outside the container.
    ln -s /config/"Online Backup" /opt/local/"Online Backup" && \
    # Fix PAM authentication for web interface.
    ln -s base-auth /etc/pam.d/common-auth

# Install dependencies.
RUN \
    add-pkg \
        dpkg \
        mkpasswd

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/cloudberry-backup-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "MSP360 Backup" && \
    set-cont-env APP_VERSION "$CLOUDBERRYBACKUP_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Set public environment variables.
ENV \
    CBB_WEB_INTERFACE_USER="" \
    CBB_WEB_INTERFACE_PASSWORD=""

# Define mountable directories.
VOLUME ["/storage"]

# Expose ports.
#   - 43210: CloudBerry Backup web interface (HTTP).
#   - 43211: CloudBerry Backup web interface (HTTPs).
EXPOSE 43210 43211

# Metadata.
LABEL \
      org.label-schema.name="cloudberry-backup" \
      org.label-schema.description="Docker container for MSP360 Backup" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-cloudberry-backup" \
      org.label-schema.schema-version="1.0"
