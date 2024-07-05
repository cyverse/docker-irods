# docker-irods

[![Docker Hub Badge](https://img.shields.io/docker/pulls/cyverse/irods)](https://hub.docker.com/r/cyverse/irods)

This repository has the source for a Docker image intended to be a base image for an iRODS server. It creates the image that can be found on Dockerhub at `cyverse/irods`.

## Design

This image is intended to be a base image. I.e., it is not intended to have containers instantiated from it directly. As a consequence, exposing volumes and ports is left to the derived images. Likewise, no configuration files have been modified from their defaults.

The image defines one environment variable to hold the password of the clerver user, `IRODS_CLERVER_PASSWORD`. It sets the value to `rods`. It is needed by the entry point to initialize the authentication file, since this file cannot be in the image.

The entry point starts and stops the iRODS service. On start, if it's a catalog consumer, it waits until a catalog provider can be detected before authenticating the clerver user and start the iRODS service. This means that bringing up the consumer need not wait for the provider to be running. The entry point traps `SIGTERM` passed down from Docker and stops the service before shutting down. Using a `CMD` instruction, a derived image can pass in an executable that the entry point will call before and after both starting and stopping the service.

The entry point allows for an executable to be provided by a derived image through a `CMD` instruction in its Dockerfile. This executable must accept four commands as its last argument. These commands tell the executable the current stage of the service's execution. Here are the commands.

* `before_start` - The executable is called with this before the iRODS service is started. If it's a catalog consumer, catalog provider detection occurs afterwards. This allows the container to perform any setup operations that need to occur before the iRODS service is started.
* `after_start` - The executable is called with this after the iRODS service is started. This allows the container to perform any setup operations that need to occur when the service is running.
* `before_stop` - The executable is called with this before the iRODS service is stopped. This allows the container to perform any tear down operations that need to occur when the service is running.
* `after_stop` - The executable is called with this argument after the iRODS service has stopped. This allows the container to perform any tear down operations that need to occur after the service has stopped.

Here's an example of a bash script, `control-status.sh`, that could be used to set the status of a given resource as `up` when its server is started and `down` when stopped.

```bash
#!/usr/bin/env bash

resc="$1"

case "$2" in
   after_start)
      iadmin modresc "$resc" status up
      ;;
   before_stop)
      iadmin modresc "$resc" status down
      ;;
   *)
      ;;
esac
```

Here's a snippet from the derived image's Dockerfile showing how the bash script can be provided to the entry point.

```Dockerfile
FROM cyverse/irods:4.3.1

### other stuff

COPY control-status.sh /control-status.sh
RUN chmod +x /control-status.sh

CMD [ "/control-status.sh", "CoordRes" ]
```

For convenience, the file `/IRODS_VERSION` in the image contains the version of iRODS in the image. The file has the version number on the first line.

```console
prompt> cat /IRODS_VERSION
4.3.1
```

## Building the Base Image

The command `./build` can be used to build the image. It creates the image `cyverse/irods` with tag `new`. The version of iRODS in the image is set in the file `./VERSION`.

```console
prompt> ./build
prompt> docker images
REPOSITORY     TAG          IMAGE ID       CREATED          SIZE
cyverse/irods  new          5a27e7f8c547   10 seconds ago   484MB
```

## Publishing the Base Image

The command `./publish` can be used to publish the image to Dockerhub. It publishes the image with three tags: _IRODS-VERSION_`_`_PUBLISH-TIMESTAMP_, _IRODS-VERSION_, and `latest`. _IRODS-VERSION_ is the _MAJOR_`.`_MINOR_`.`_INCREMENTAL_ version of iRODS in the image. _PUBLISH-TIMESTAMP_ is the UTC date and time when the image was published to Dockerhub in the ISO 8601 form _YYYY_`-`_MM_`-`_DD_`T`_hh_`-`_mm_`-`_ss_ where _YYYY_ is the four digit year, _MM_ is the two digit month of the year number, _DD_ is the two digit day of the month number, _hh_ is the two digit hour of the day, _mm_ is the two digit minutes past the hour, and _ss_ is the two digit seconds past the minute. Here's an example set of tagged images.

```console
prompt> date --utc
Fri Mar 08 19:34:57 UTC 2024
prompt> ./build
prompt> docker images
REPOSITORY      TAG                          IMAGE ID       CREATED          SIZE
cyverse/irods   latest                       5a27e7f8c547   12 minutes ago   484MB
cyverse/irods   4.3.1                        5a27e7f8c547   12 minutes ago   484MB
cyverse/irods   4.3.1_2024-03-08T19-35-08    5a27e7f8c547   12 minutes ago   484MB
```

> **NOTE**
> An image is published every time the main branch is updated on Github.
