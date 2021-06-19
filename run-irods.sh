#!/bin/bash
#
# Usage:
#  run-irods [PERIPHERY-EXEC [ARG ...]]
#
# Options:
#  PERIPHERY-EXEC  an executable that will perform any setup and tear down tasks
#  ARG             an argument passed to PERIPHERY-EXEC
#
# PERIPHERY_EXEC must accept four commands as its last argument. These commands
# tell the executable the current stage of the service's execution. Here are the
# commands.
#
# before_start  The executable is called with this before the iRODS service is
#               started. If it's a catalog consumer, catalog provider detection
#               occurs afterwards. This allows the container to perform any
#               setup operations that need to occur before the iRODS service is
#               started.
# after_start   The executable is called with this after the iRODS service is
#               started. This allows the container to perform any setup
#               operations that need to occur when the service is running.
# before_stop   The executable is called with this before the iRODS service is
#               stopped. This allows the container to perform any tear down
#               operations that need to occur when the service is running.
# after_stop    The executable is called with this argument after the iRODS
#               service has stopped. This allows the container to perform any
#               tear down operations that need to occur after the service has
#               stopped.
#
# After `PERIPHERY_EXEC ARG ... after_start` has completed, the script waits for
# a SIGTERM, before calling `PERIPHERY_EXEC ARG ... before_stop`.
#
# This script expects the following environment variables to be defined.
#
# IRODS_CLERVER_PASSWORD   the clerver user password

set -o errexit -o nounset -o pipefail

declare PERIPHERY_EXEC

declare TailPid


main() {
  if [[ "$#" -ge 1 ]]
  then
    PERIPHERY_EXEC="$*"
  fi
  readonly PERIPHERY_EXEC

  if ! configured
  then
    printf 'iRODS isn not configured. Exiting\n' >&2
    return 1
  fi

  if am_provider
  then
    printf 'Starting catalog provider\n'
    start_server
    init_clerver_session localhost
  else
    printf 'Starting catalog consumer\n'
    init_clerver_session "$(wait_for_provider)"
    start_server
  fi

  trap stop_server SIGTERM

  printf 'Ready\n'

  local irodsPid
  while irodsPid=$(pidof -s /usr/sbin/irodsServer)
  do
    tail --follow /dev/null --pid "$irodsPid" &
    TailPid="$!"
    wait "$TailPid"
    TailPid=
  done
}


configured() {
  [[ -e /etc/irods/server_config.json ]] && [[ -e /var/lib/irods/.irods/irods_environment.json ]]
}


init_clerver_session() {
  local provider="$1"

  IRODS_HOST="$provider" iinit "$IRODS_CLERVER_PASSWORD"
}


start_server() {
  call_periphery before_start
  /var/lib/irods/irodsctl start
  call_periphery after_start
}


stop_server() {
  call_periphery before_stop
  /var/lib/irods/irodsctl stop
  call_periphery after_stop

  if [[ -n "$TailPid" ]]
  then
    if kill "$TailPid" 2> /dev/null
    then
      wait "$TailPid"
    fi
  fi
}


call_periphery() {
  local cmd="$1"

  if [[ -n "$PERIPHERY_EXEC" ]]
  then
    eval "$PERIPHERY_EXEC" "$cmd"
  fi
}


am_provider() {
  [[ "$(query_server_config .plugin_configuration.database)" != null ]]
}


wait_for_provider() {
  local zonePort
  zonePort="$(query_server_config .zone_port)"

  # Wait for a provider to become available
  while true
  do
    local provider
    for provider in $(query_server_config '.catalog_provider_hosts | .[]')
    do
      printf 'Waiting for a provider\n' >&2

      if exec 3<> /dev/tcp/"$provider"/"$zonePort" 2> /dev/null
      then
        exec 3>&-
        exec 3<&-
        echo "$provider"
        return
      fi
    done

    sleep 1
  done
}


query_server_config() {
  local query="$1"

  jq -r "$query" /etc/irods/server_config.json
}


main "$@"
