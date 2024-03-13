FROM cyverse/irods:new

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=target=/tmp/unattended_installation.json,source=unattended_installation.json \
### Installed required packages
	apt-get --quiet update && \
	apt-get --quiet --yes upgrade && \
	apt-get --quiet --yes install \
		irods-database-plugin-postgres postgresql postgresql-contrib python-is-python3 && \
	apt-get clean && \
### Initialize server
	echo 'irods ALL=(postgres) NOPASSWD: ALL' > /etc/sudoers.d/irods && \
	sudo --login --user=postgres \
		/usr/lib/postgresql/14/bin/pg_ctl \
			--log=/var/log/postgresql/postgresql-14-main.log \
			--options='--config_file=/etc/postgresql/14/main/postgresql.conf' \
			--pgdata=/var/lib/postgresql/14/main \
			start && \
	sudo --user=postgres psql --command="CREATE USER irods WITH PASSWORD 'testpassword'" && \
	sudo --user=postgres psql --command='CREATE DATABASE "ICAT"' && \
	sudo --user=postgres psql --command='GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods' && \
	python /var/lib/irods/scripts/setup_irods.py --verbose \
		--json_configuration_file=/tmp/unattended_installation.json && \
	sudo --login --user=postgres \
		/usr/lib/postgresql/14/bin/pg_ctl --pgdata=/var/lib/postgresql/14/main stop

### Install DBMS management script
COPY --chown=irods:irods --chmod=550 control-dbms.sh /control-dbms

USER irods

CMD [ "/control-dbms" ]