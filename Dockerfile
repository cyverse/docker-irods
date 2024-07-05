FROM ubuntu:22.04

### Install iRODS server
ADD --chmod=444 \
	https://packages.irods.org/irods-signing-key.asc /etc/apt/trusted.gpg.d/irods-signing-key.asc

COPY apt.irods /etc/apt/preferences.d/irods

ARG DEBIAN_FRONTEND=noninteractive

RUN <<EOF
	set -o errexit
	apt-get update
	apt-get --yes install apt-utils
	apt-get --yes install ca-certificates gnupg lsb-release

	echo deb [arch=amd64] https://packages.irods.org/apt/ "$(lsb_release --codename --short)" main \
		> /etc/apt/sources.list.d/renci-irods.list

	# iRODS service account created before iRODS installed so that account will own /var/lib/irods
	adduser --group --quiet --system \
		--gecos 'iRODS Administrator' --home /var/lib/irods --shell /bin/bash \
		irods

	apt-get update
	apt-get --yes install irods-server

### Initialize server
	apt-get --yes install jq
	jq ".installation_time |= \"$(date '+%Y-%m-%dT%T.%6N')\"" /var/lib/irods/version.json.dist \
		> /var/lib/irods/version.json
	mkdir /var/lib/irods/.irods
	chown --recursive irods:irods /var/lib/irods

### Install dumb-init
	apt-get --yes install dumb-init
	apt-get clean
EOF

### Install iRODS management script
COPY --chown=irods:irods --chmod=550 run-irods.sh /run-irods

WORKDIR /var/lib/irods
USER irods

ENV IRODS_CLERVER_PASSWORD=rods

ENTRYPOINT [ "/usr/bin/dumb-init", "--", "/run-irods" ]
