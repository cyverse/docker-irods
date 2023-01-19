# docker-irods

This repository has the source for a Docker image intended to be a base image for an iRODS server.
It creates the image that can be found on Dockerhub at `cyverse/irods`.

## Design

This image is intended to be a base image. I.e., it is not intended to have containers instantiated
from it directly. As a consequence, exposing volumes and ports is left to the derived images.
Likewise, no configuration files have been modified from their defaults.

The image defines one environment variable to hold the password of the clerver user,
`IRODS_CLERVER_PASSWORD`. It sets the value to `rods`. It is needed by the entry point to
initialize the authentication file, since this file cannot be in the image.

The entry point starts and stops the iRODS service. On start, if it's a catalog consumer, it waits
until a catalog provider can be detected before authenticating the clerver user and start the iRODS
service. This means that bringing up the consumer need not wait for the provider to be running. The
entry point traps `SIGTERM` passed down from Docker and stops the service before shutting down.
Using a `CMD` instruction, a derived image can pass in an executable that the entry point will call
before and after both starting and stopping the service.

The entry point allows for an executable to be provided by a derived image through a `CMD`
instruction in its Dockerfile. This executable must accept four commands as its last argument.
These commands tell the executable the current stage of the service's execution. Here are the
commands.

* `before_start` - The executable is called with this before the iRODS service is started. If it's a
catalog consumer, catalog provider detection occurs afterwards. This allows the container to perform
any setup operations that need to occur before the iRODS service is started.
* `after_start` - The executable is called with this after the iRODS service is started. This allows
the container to perform any setup operations that need to occur when the service is running.
* `before_stop` - The executable is called with this before the iRODS service is stopped. This
allows the container to perform any tear down operations that need to occur when the service is
running.
* `after_stop` - The executable is called with this argument after the iRODS service has stopped.
This allows the container to perform any tear down operations that need to occur after the service
has stopped.

Here's an example of a bash script, `control-status.sh`, that could be used to set the status of a
given resource as `up` when its server is started and `down` when stopped.

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

Here's a snippet from the derived image's Dockerfile showing how the bash script can be provided to
the entry point.

```Dockerfile
FROM cyverse/irods:4.2.8

### other stuff

COPY control-status.sh /control-status.sh
RUN chmod +x /control-status.sh

CMD [ "/control-status.sh", "CoordRes" ]
```

## Building the Base Image

The command `./build` can be used to build the image.

Each time an image is built, it is tagged with the iRODS version and the UTC time when the build
started separated by an underscore. The tag has an ISO 8601 style form
_`YYYY`_`-`_`MM`_`-`_`DD`_`T`_`hh`_`-`_`mm`_`-`_`ss`_ where _YYYY_ is the four digit year, _MM_ is
the two digit month of the year number, _DD_ is the two digit day of the month number, _hh_ is the
two digit hour of the day, _**mm**_ is the two digit minutes past the hour, and _ss_ is the two
digit seconds past the minute. Here's an example tag: `4.2.8_2021-06-11T21-46-59`. The latest
version of an image for a given iRODS version will be tagged with the iRODS version.

```console
prompt> date -u
Fri Jun 11 21:47:20 UTC 2021
prompt> ./build
prompt> docker images
REPOSITORY      TAG                         IMAGE ID       CREATED          SIZE
cyverse/irods   4.2.8                       01c7f4dda2c9   11 seconds ago   454MB
cyverse/irods   4.2.8_2021-06-11T21-46-59   01c7f4dda2c9   11 seconds ago   454MB
centos          7                           8652b9f0cb4c   6 months ago     204MB
```

If the `-p` or `--push` option is provided to `build`, the image will be pushed to Dockerhub if a
new image was created.
