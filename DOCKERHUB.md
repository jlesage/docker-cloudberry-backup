# Docker container for MSP360 Backup (formerly CloudBerry)
[![Release](https://img.shields.io/github/release/jlesage/docker-cloudberry-backup.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-cloudberry-backup/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/cloudberry-backup/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/cloudberry-backup/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/cloudberry-backup?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/cloudberry-backup)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/cloudberry-backup?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/cloudberry-backup)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-cloudberry-backup/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-cloudberry-backup/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-cloudberry-backup)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [MSP360 Backup](https://www.msp360.com/backup/).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

---

[![MSP360 Backup logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/cloudberry-backup-icon.png&w=110)](https://www.msp360.com/backup/)[![MSP360 Backup](https://images.placeholders.dev/?width=416&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=MSP360%20Backup&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.msp360.com/backup/)

Backup files and folders to cloud storage of your choice: Amazon S3, Azure Blob
Storage, Google Cloud Storage, HP Cloud, Rackspace Cloud Files, OpenStack,
DreamObjects and other.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the MSP360 Backup docker container with the following command:
```shell
docker run -d \
    --name=cloudberry-backup \
    -p 5800:5800 \
    -v /docker/appdata/cloudberry-backup:/config:rw \
    -v /home/user:/storage:ro \
    jlesage/cloudberry-backup
```

Where:

  - `/docker/appdata/cloudberry-backup`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the MSP360 Backup GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-cloudberry-backup.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-cloudberry-backup/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
