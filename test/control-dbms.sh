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
