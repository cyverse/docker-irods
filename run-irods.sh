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


set -o errexit

declare PeripheryExec
declare TailPid


main()
{
  if [[ "$#" -ge 1 ]]
  then
    PeripheryExec="$*"
  fi

  call_periphery before_start
  local provider="$(wait_for_provider)"
  init_clerver_session "$provider"
  trap stop_server SIGTERM
  start_server
}


call_periphery()
{
  local cmd="$1"

  if [[ -n "$PeripheryExec" ]]
  then
    eval "$PeripheryExec" "$cmd"
  fi
}


init_clerver_session()
{
  local provider="$1"

  IRODS_HOST="$provider" iinit "$IRODS_CLERVER_PASSWORD"
}


start_server()
{
  /var/lib/irods/irodsctl start
  call_periphery after_start
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


wait_for_provider()
{
  local zonePort
  zonePort=$(jq -r '.zone_port' /etc/irods/server_config.json)

  # Wait for a provider to become available
  while true
  do
    local provider
    for provider in "$(jq -r '.catalog_provider_hosts | .[]' /etc/irods/server_config.json)"
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


main "$@"
