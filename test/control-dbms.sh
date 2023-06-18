#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

main() {
	case "$1" in
		before_start)
			start_dbms
			;;
		after_stop)
			stop_dbms
			;;
		*)
			;;
	esac
}


start_dbms() {
	printf 'Starting PostgreSQL\n'

	sudo --user postgres \
		/usr/lib/postgresql/10/bin/pg_ctl \
			--log=/var/log/postgresql/postgresql-10-main.log \
			--options='--config_file=/etc/postgresql/10/main/postgresql.conf' \
			--pgdata=/var/lib/postgresql/10/main \
			start
}


stop_dbms() {
	printf 'Stopping PostgreSQL\n'
	sudo --user postgres /usr/lib/postgresql/10/bin/pg_ctl --pgdata=/var/lib/postgresql/10/main stop
}


main "$@"
