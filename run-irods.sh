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


set -e

declare PeripheryExec
declare TailPid


main()
{
  if [[ "$#" -ge 1 ]]
  then
    PeripheryExec="$*"
  fi

  call_periphery before_start
  wait_for_ies
  init_clerver_session
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
  local icatHost
  icatHost=$(jq -r '.icat_host' /etc/irods/server_config.json)

  IRODS_HOST="$icatHost" iinit "$IRODS_CLERVER_PASSWORD"
}


start_server()
{
  /var/lib/irods/iRODS/irodsctl start
  call_periphery after_start
  printf 'Ready\n'

  local irodsPid
  while irodsPid=$(pidof -s /var/lib/irods/iRODS/server/bin/irodsServer)
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
  /var/lib/irods/iRODS/irodsctl stop
  call_periphery after_stop

  if [[ -n "$TailPid" ]]
  then
    if kill "$TailPid" 2> /dev/null
    then
      wait "$TailPid"
    fi
  fi
}


wait_for_ies()
{
  local icatHost
  icatHost=$(jq -r '.icat_host' /etc/irods/server_config.json)

  local zonePort
  zonePort=$(jq -r '.zone_port' /etc/irods/server_config.json)


  # Wait for IES to become available
  until exec 3<> /dev/tcp/"$icatHost"/"$zonePort"
  do
    printf 'Waiting for IES\n'
    sleep 1
  done 2> /dev/null

  exec 3<&-
  exec 3>&-
}


main "$@"
