#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

main() {
	case "$1" in
		before_start)
			resolve_irods_host
			start_dbms
			;;
		after_start)
			printf 'after_start received\n'
			;;
		before_stop)
			printf 'before_stop received\n'
			;;
		after_stop)
			stop_dbms
			;;
		*)
			;;
	esac
}

resolve_irods_host() {
	printf 'Resolving host name\n'

	local host
	host="$(hostname)"

	jq '.irods_host |= "'"$host"'"' /var/lib/irods/.irods/irods_environment.json \
		| sponge /var/lib/irods/.irods/irods_environment.json

	indent /dev/stdout < /var/lib/irods/.irods/irods_environment.json
}

start_dbms() {
	printf 'Starting PostgreSQL\n'

	sudo --login --user=postgres \
			/usr/lib/postgresql/14/bin/pg_ctl \
				--log=/var/log/postgresql/postgresql-14-main.log \
				--options='--config_file=/etc/postgresql/14/main/postgresql.conf' \
				--pgdata=/var/lib/postgresql/14/main \
				start \
		> >(indent /dev/stdout) \
		2> >(indent /dev/stderr)
}

stop_dbms() {
	printf 'Stopping PostgreSQL\n'

	sudo --login --user=postgres \
			/usr/lib/postgresql/14/bin/pg_ctl --pgdata=/var/lib/postgresql/14/main stop \
		> >(indent /dev/stdout) \
		2> >(indent /dev/stderr)
}

indent() {
	local out="$1"

	local line
	while read -r line; do
		printf '\t%s\n' "$line"
	done > "$out"
}

main "$@"
