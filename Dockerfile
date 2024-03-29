FROM ubuntu:18.04

### Update installed packages to latest version
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get --quiet update && \
	apt-get --quiet --yes install apt-utils 2>&1 && \
	apt-get --quiet --yes upgrade && \
#
### Install dumb-init
	apt-get --quiet --yes install dumb-init && \
	apt-get clean && \
#
### Install iRODS server
# 	iRODS service account created before iRODS installed so that account will own
# 	/var/lib/irods
	adduser --group --quiet --system \
		--gecos 'iRODS Administrator' --home /var/lib/irods --shell /bin/bash \
		irods
COPY apt.irods /etc/apt/preferences.d/irods
ADD https://packages.irods.org/irods-signing-key.asc /tmp/irods-signing-key.asc
RUN apt-get --quiet --yes install ca-certificates gnupg lsb-release && \
	apt-key add /tmp/irods-signing-key.asc 2>&1 && \
	echo deb [arch=amd64] https://packages.irods.org/apt/ "$(lsb_release --codename --short)" main \
		> /etc/apt/sources.list.d/renci-irods.list && \
	apt-get --quiet update && \
	apt-get --quiet --yes install irods-server && \
#
### Install iRODS management script dependencies
	apt-get --quiet --yes install jq && \
	apt-get clean && \
#
### Initialize server
	jq ".installation_time |= \"$(date '+%Y-%m-%dT%T.%6N')\"" /var/lib/irods/version.json.dist \
		> /var/lib/irods/version.json && \
	mkdir /var/lib/irods/.irods && \
	chown --recursive irods:irods /var/lib/irods

### Install iRODS management script
COPY run-irods.sh /run-irods
RUN chown irods:irods /run-irods && \
	chmod ug+x /run-irods

WORKDIR /var/lib/irods
USER irods

ENV IRODS_CLERVER_PASSWORD=rods

ENTRYPOINT [ "/usr/bin/dumb-init", "--", "/run-irods" ]
