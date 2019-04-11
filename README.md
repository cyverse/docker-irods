# docker-irods-rs

This repository has the source for a docker image intended to be a base image
for an iRODS resource server. It creates the image that can be found on
dockerhub at `cyverse/irods-rs`.


## Design

__TODO__ Finish this. Discuss configuration values, volumes, ports, and how run-irods works.

Here are the required environment variables.

Environment Variable      | Description
------------------------- | -----------
`IRODS_CLERVER_PASSWORD`  | the password used to authenticate the clerver user


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

```bash
prompt> date -u
Wed Apr 10 23:47:11 UTC 2019

prompt> ./build

prompt> docker images
REPOSITORY          TAG                          IMAGE ID            CREATED              SIZE
cyverse/irods-rs    4.1.10                       551961059431        About a minute ago   392MB
cyverse/irods-rs    4.1.10_2019-04-10T23-47-39   551961059431        About a minute ago   392MB
centos              7                            9f38484d220f        3 weeks ago          202MB
```
