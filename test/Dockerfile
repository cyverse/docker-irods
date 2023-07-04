FROM cyverse/irods:latest

USER root

ARG DEBIAN_FRONTEND=noninteractive

COPY unattended_installation.json /tmp

RUN apt-get --quiet update && \
	apt-get --quiet --yes upgrade && \
	apt-get --quiet --yes install irods-database-plugin-postgres postgresql postgresql-contrib && \
	apt-get clean && \
### Create ICAT DB
	sudo --user postgres \
		/usr/lib/postgresql/10/bin/pg_ctl \
			--log=/var/log/postgresql/postgresql-10-main.log \
			--options='--config_file=/etc/postgresql/10/main/postgresql.conf' \
			--pgdata=/var/lib/postgresql/10/main \
			start && \
	sudo --user postgres psql --command="CREATE USER irods WITH PASSWORD 'testpassword'" && \
	sudo --user postgres psql --command='CREATE DATABASE "ICAT"' && \
	sudo --user postgres psql --command='GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods' && \
### Initialize server
	python3 /var/lib/irods/scripts/setup_irods.py --verbose \
		--json_configuration_file=/tmp/unattended_installation.json && \
	sudo --user postgres \
		/usr/lib/postgresql/10/bin/pg_ctl --pgdata=/var/lib/postgresql/10/main stop && \
	rm /tmp/unattended_installation.json

### Install DBMS management script
COPY control-dbms.sh /control-dbms

RUN chown irods:irods /control-dbms && \
	chmod ug+x /control-dbms && \
	echo 'irods ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/irods

USER irods

CMD [ "/control-dbms" ]
