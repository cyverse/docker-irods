# docker-irods-rs

This repository has the source for a docker image intended to be a base image
for an iRODS resource server. It creates the image that can be found on
dockerhub at `cyverse/irods-rs`.


## Design

This image is intended to be a base image. I.e., it is not intended to have
containers instantiated from it directly. As a consequence, exposing volumes
and ports is left to the derived images. Likewise, no configuration files have
been modified from their defaults.

The image defines one environment variable to hold the password of the clerver
user, `IRODS_CLERVER_PASSWORD`. It sets the value to `rods`. It is needed by the
entry point to initialize the authentication file, since this file cannot be in
the image.

The entry point starts and stops the resource server. On start, it waits until
the IES can be detected before authenticating the clerver user and start the
resource service. This means that bringing up the resource server need not wait
for the IES to be running. The entry point traps `SIGTERM` passed down from
docker and stops the service before shutting down. Using a `CMD` instruction, a
derived image can pass in an executable that the entry point will call before
and after both starting and stopping the resource service.

The entry point allows for an executable to be provided by a derived image
through a `CMD` instruction in its dockerfile. This executable must accept four
commands as its last argument. These commands tell the executable the
current stage of the service's execution. Here are the commands.

* `before_start`  The executable is called with this before the IES is detected.
It allows the container to perform any setup operations that need to occur
before the resource service is started.
* `after_start`  The executable is called with this immediately after the
resource service is started. It allows the container to perform any setup
operations that need to occur when the service is running.
* `before_stop`  The executable is called with this immediately before the
resource service is stopped. It allows the container to perform any tear down
operations that need to occur when the service is running.
* `after_stop`  The executable is called with this argument after the resource
service has stopped. It allows the container to perform any tear down operations
that need to occur after the service has stopped.

Here's an example of a bash script, `control-status.sh`, that could be used to
set the status of a given resource as `up` when its server is started and `down`
when stopped.

```bash
#!/bin/bash

Resc="$1"

case "$2" in
  after_start)
    iadmin modresc "$Resc" status up
    ;;
  before_stop)
    iadmin modresc "$Resc" status down
    ;;
  *)
    ;;
esac
```

Here's a snippet from the derived image's Dockerfile showing how the bash script
can be provided to the entry point.

```Dockerfile
FROM cyverse/irods-rs:4.1.10

### other stuff

COPY control-status.sh /control-status.sh
RUN chmod +x /control-status.sh

CMD [ "/control-status.sh", "CoordRes" ]
```


## Building the Base Image

The command `./build` can be used to build the image.

Each time an image is built, it is tagged with the iRODS version and the UTC
time when the build started separated by an underscore. The tag has an ISO 8601
style form _**yyyy**-**MM**-**dd**T**hh**-**mm**-**ss**_ where _**yyyy**_ is the
four digit year, _**MM**_ is the two digit month of the year number, _**dd**__
is the two digit day of the month number, _**hh**_ is the two digit hour of the
day, _**mm**_ is the two digit minutes past the hour, and _**ss**_ is the two
digit seconds past the minute. Here's an example tag:
`4.1.10_2019-04-09T22-32-49`. The latest version of an image for a given iRODS
version will be tagged with the iRODS version.

```
prompt> date -u
Wed Apr 10 23:47:11 UTC 2019

prompt> ./build

prompt> docker images
REPOSITORY          TAG                          IMAGE ID            CREATED              SIZE
cyverse/irods-rs    4.1.10                       551961059431        About a minute ago   392MB
cyverse/irods-rs    4.1.10_2019-04-10T23-47-39   551961059431        About a minute ago   392MB
centos              7                            9f38484d220f        3 weeks ago          202MB
```
