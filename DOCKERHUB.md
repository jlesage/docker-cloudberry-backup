# Docker container for CloudBerry Backup
[![Docker Image Size](https://img.shields.io/microbadger/image-size/jlesage/cloudberry-backup)](http://microbadger.com/#/images/jlesage/cloudberry-backup) [![Build Status](https://drone.le-sage.com/api/badges/jlesage/docker-cloudberry-backup/status.svg)](https://drone.le-sage.com/jlesage/docker-cloudberry-backup) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-cloudberry-backup.svg)](https://github.com/jlesage/docker-cloudberry-backup/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage/0usd)

This is a Docker container for [CloudBerry Backup](https://www.cloudberrylab.com/backup/linux.aspx).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via any VNC client.

---

[![CloudBerry Backup logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/cloudberry-backup-icon.png&w=200)](https://www.cloudberrylab.com/backup/linux.aspx)[![CloudBerry Backup](https://dummyimage.com/400x110/ffffff/575757&text=CloudBerry+Backup)](https://www.cloudberrylab.com/backup/linux.aspx)

Backup files and folders to cloud storage of your choice: Amazon S3, Azure Blob Storage, Google Cloud Storage, HP Cloud, Rackspace Cloud Files, OpenStack, DreamObjects and other.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the CloudBerry Backup docker container with the following command:
```
docker run -d \
    --name=cloudberry-backup \
    -p 5800:5800 \
    -v /docker/appdata/cloudberry-backup:/config:rw \
    -v $HOME:/storage:ro \
    jlesage/cloudberry-backup
```

Where:
  - `/docker/appdata/cloudberry-backup`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.

Browse to `http://your-host-ip:5800` to access the CloudBerry Backup GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-cloudberry-backup.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-cloudberry-backup/issues
