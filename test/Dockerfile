FROM cyverse/irods:4.2.11

### Install PostgreSQL
USER root
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get --quiet update
RUN apt-get --quiet --yes upgrade
RUN apt-get --quiet --yes install postgresql postgresql-contrib

### Create ICAT DB
USER postgres
RUN /usr/lib/postgresql/10/bin/pg_ctl \
		--log=/var/log/postgresql/postgresql-10-main.log \
		--options='--config_file=/etc/postgresql/10/main/postgresql.conf' \
		--pgdata=/var/lib/postgresql/10/main \
		start && \
	psql --command="CREATE USER irods WITH PASSWORD 'testpassword'" && \
	psql --command='CREATE DATABASE "ICAT"' && \
	psql --command='GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods' && \
	/usr/lib/postgresql/10/bin/pg_ctl --pgdata=/var/lib/postgresql/10/main stop

### Install iRODS Database Plugin
USER root
RUN apt-get --quiet --yes install irods-database-plugin-postgres

### Initialize server
COPY unattended_installation.json /tmp
RUN rm /var/lib/irods/version.json
RUN sudo --user postgres \
		/usr/lib/postgresql/10/bin/pg_ctl \
			--log=/var/log/postgresql/postgresql-10-main.log \
			--options='--config_file=/etc/postgresql/10/main/postgresql.conf' \
			--pgdata=/var/lib/postgresql/10/main \
			start && \
	python3 /var/lib/irods/scripts/setup_irods.py --verbose \
		--json_configuration_file=/tmp/unattended_installation.json && \
	sudo --user irods /var/lib/irods/irodsctl stop && \
	sudo --user postgres /usr/lib/postgresql/10/bin/pg_ctl --pgdata=/var/lib/postgresql/10/main stop

ENTRYPOINT /bin/bash
