#
# clouberry-backup Dockerfile
#
# https://github.com/jlesage/docker-cloudberry-backup
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-glibc-v1.5.0

# Define working directory.
WORKDIR /tmp

# Install CloudBerry Backup.
RUN \
    # Install packages needed by the build.
    apk --no-cache add --virtual build-dependencies binutils curl bash && \

    # Download the CloudBerry Backup package.
    echo "Downloading CloudBerry Backup package..." && \
    curl -# -o cloudberry-backup.deb \
        -F "__EVENTTARGET=" \
        -F "prod=cbbub1214" \
        https://www.cloudberrylab.com/download-thanks.aspx && \

    # Extract the CloudBerry Backup package.
    ar vx cloudberry-backup.deb && \
    tar xf control.tar.gz && \
    tar xf data.tar.gz -C / && \

    # Install CloudBerry Backup.
    ./postinst && \

    # Modify installed scripts to use sh instead of bash.
    sed -i 's/^#!\/bin\/bash/#!\/bin\/sh/' /opt/local/CloudBerry\ Backup/bin/* && \

    # Save default configuration.
    mv /opt/local/"CloudBerry Backup"/etc /opt/local/"CloudBerry Backup"/etc.default && \

    # Setup symbolic links for stuff that need to be outside the container.
    ln -s /config/etc /opt/local/"CloudBerry Backup"/etc && \
    rm -r /opt/local/"CloudBerry Backup"/logs && \
    ln -s /config/logs /opt/local/"CloudBerry Backup"/logs && \
    ln -s /config/HID /opt/local/"CloudBerry Backup"/share/HID && \

    # Maximize only the main/initial window.
    sed -i 's/<application type="normal">/<application type="normal" title="CloudBerry Backup">/' \
        $HOME/.config/openbox/rc.xml && \

    # Cleanup.
    apk --no-cache del build-dependencies && \
    rm -rf /tmp/*

# Install dependencies.
RUN apk --no-cache add \
    ca-certificates

# Generate and install favicons.
ARG APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/cloudberry-backup-icon.png
RUN /opt/install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Cloudberry Backup"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="cloudberry-backup" \
      org.label-schema.description="Docker container for CloudBerry Backup" \
      org.label-schema.version="0.1.0" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-cloudberry-backup" \
      org.label-schema.schema-version="1.0"
