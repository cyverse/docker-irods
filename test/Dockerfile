FROM cyverse/irods:4.2.11

USER root

### Install PostgreSQL
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get --quiet update
RUN apt-get --quiet --yes upgrade
RUN apt-get --quiet --yes install postgresql postgresql-contrib
