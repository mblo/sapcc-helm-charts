#!/usr/bin/env bash

set -o pipefail
set -x

{{- include "tempest-base.function_start_tempest_tests" . }}

function cleanup_tempest_leftovers() {

  echo " ============ Fetching Tempest logs ============ "
  TEMPEST_LOG_FILE=$(find /home/rally/.rally/verification -iname tempest.log)
  cat $TEMPEST_LOG_FILE

  echo " ============ Running cleanup ============ "
  # Delete loadbalancers, lb flavors, pools, members for Admin
  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'

  for lb in $(openstack loadbalancer list -f value -c name | grep -E "tempest-lb"); do
    echo "Loadbalancer ${lb} will be deleted"
    if ! openstack loadbalancer delete --cascade --wait ${lb}; then
      # if some loadbalancer was not deleted we cannot cleanup all other resources
      # because in this case the loadbalancer will stuck in ERROR or PANDING_* status
      return 1
    fi
  done

  for flavor in $(openstack loadbalancer flavor list | grep -E "tempest-lb" | awk '{ print $4 }'); do
    echo "Loadbalancer flavor ${flavor} will be deleted"
    openstack loadbalancer flavor delete ${flavor}
  done

  for server in $(openstack server list --all -f value | grep -E "tempest-lb" | awk '{print $1 }'); do
    echo "Server ${server} will be deleted"
    openstack server delete ${server}
  done

  for network in $(openstack network list -f value | grep -E "tempest-lb" | awk '{ print $1 }'); do
    for port in $(openstack port list --network="$network" -f value -c ID); do
      echo "Port $port will be disabled and deleted"
      openstack port set ${port} --disable --no-fixed-ip && openstack port delete ${port}
    done

    for subnet in $(openstack subnet list --network="$network" -f value -c ID); do
      echo "Subnet ${subnet} will be deleted"
      openstack subnet delete ${subnet}
    done

    echo "Network $network will be deleted"
    openstack network delete $network
  done

  for secgroup in $(openstack security group list | grep -oP "tempest-\w*[A-Z]+\S+"); do
    openstack security group delete ${secgroup}
  done
}

{{- include "tempest-base.function_main" . }}

main
