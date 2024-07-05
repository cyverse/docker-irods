FROM cyverse/irods:new

### Installed required packages
USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=target=/tmp/unattended_installation.json,source=unattended_installation.json <<EOF
	set -o errexit
	apt-get update
	apt-get --yes upgrade

	apt-get --yes install \
		irods-database-plugin-postgres moreutils postgresql postgresql-contrib python-is-python3

	apt-get clean

### Initialize server
	echo 'irods ALL=(postgres) NOPASSWD: ALL' > /etc/sudoers.d/irods

	sudo --login --user=postgres \
		/usr/lib/postgresql/14/bin/pg_ctl \
			--log=/var/log/postgresql/postgresql-14-main.log \
			--options='--config_file=/etc/postgresql/14/main/postgresql.conf' \
			--pgdata=/var/lib/postgresql/14/main \
			start

	sudo --user=postgres psql --command="CREATE USER irods WITH PASSWORD 'testpassword'"
	sudo --user=postgres psql --command='CREATE DATABASE "ICAT"'
	sudo --user=postgres psql --command='GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods'

	jq '.service_account_environment.irods_host |= "'"$(hostname)"'"' \
			/tmp/unattended_installation.json \
		> /tmp/resolved_installation.json

		python /var/lib/irods/scripts/setup_irods.py --verbose \
		--json_configuration_file=/tmp/resolved_installation.json

	rm --force /tmp/resolved_installation.json

	sudo --login --user=postgres \
		/usr/lib/postgresql/14/bin/pg_ctl --pgdata=/var/lib/postgresql/14/main stop
EOF

### Install DBMS management script
COPY --chown=irods:irods --chmod=550 control-dbms.sh /control-dbms

USER irods

CMD [ "/control-dbms" ]
