FROM ubuntu:22.04

### Update installed packages to latest version
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
	apt-get --yes install apt-utils 2>&1 && \
	apt-get --yes upgrade && \
#
### Install dumb-init
	apt-get --yes install dumb-init && \
	apt-get clean && \
#
### Install iRODS server
# 	iRODS service account created before iRODS installed so that account will own
# 	/var/lib/irods
	adduser --group --quiet --system \
		--gecos 'iRODS Administrator' --home /var/lib/irods --shell /bin/bash \
		irods
COPY apt.irods /etc/apt/preferences.d/irods
ADD --chmod=444 \
	https://packages.irods.org/irods-signing-key.asc /etc/apt/trusted.gpg.d/irods-signing-key.asc
RUN apt-get --yes install ca-certificates gnupg lsb-release && \
	echo deb [arch=amd64] https://packages.irods.org/apt/ "$(lsb_release --codename --short)" main \
		> /etc/apt/sources.list.d/renci-irods.list && \
	apt-get update && \
	apt-get --yes install irods-server && \
#
### Install iRODS management script dependencies
	apt-get --yes install jq && \
	apt-get clean && \
#
### Initialize server
	jq ".installation_time |= \"$(date '+%Y-%m-%dT%T.%6N')\"" /var/lib/irods/version.json.dist \
		> /var/lib/irods/version.json && \
	mkdir /var/lib/irods/.irods && \
	chown --recursive irods:irods /var/lib/irods

### Install iRODS management script
COPY --chown=irods:irods --chmod=550 run-irods.sh /run-irods

WORKDIR /var/lib/irods
USER irods

ENV IRODS_CLERVER_PASSWORD=rods

ENTRYPOINT [ "/usr/bin/dumb-init", "--", "/run-irods" ]
