#!/bin/bash
#
# Usage:
#  run-irods
#
# This script starts the iRODS resource server and waits for a SIGTERM.
#
# This script expects the following environment variables to be defined.
#
# IRODS_CLERVER_PASSWORD   the clerver user password

set -o errexit -o nounset -o pipefail

declare PeripheryExec
declare TailPid


main()
{
  if [[ "$#" -ge 1 ]]
  then
    PeripheryExec="$*"
  fi

  if [[ am_provider ]]
  then
    start_server
    init_clerver_session localhost
  else
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


init_clerver_session()
{
  local provider="$1"

  IRODS_HOST="$provider" iinit "$IRODS_CLERVER_PASSWORD"
}


start_server()
{
  call_periphery before_start
  /var/lib/irods/irodsctl start
  call_periphery after_start
}


stop_server()
{
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


call_periphery()
{
  local cmd="$1"

  if [[ -n "$PeripheryExec" ]]
  then
    eval "$PeripheryExec" "$cmd"
  fi
}


am_provider()
{
  [[ "$(query_server_config .plugin_configuration.database)" != null ]]
}


wait_for_provider()
{
  local zonePort
  zonePort="$(query_server_config .zone_port)"

  # Wait for a provider to become available
  while true
  do
    local provider
    for provider in "$(query_server_config '.catalog_provider_hosts | .[]')"
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


query_server_config()
{
  local query="$1"

  jq -r "$query" /etc/irods/server_config.json
}


main "$@"
