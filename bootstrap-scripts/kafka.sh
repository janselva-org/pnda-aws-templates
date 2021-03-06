#!/bin/bash -v

# This script runs on instances with a node_type tag of "kafka"
# It sets the roles that determine what software is installed
# on this instance by platform-salt scripts and the minion
# id and hostname

# The pnda_env-<cluster_name>.sh script generated by the CLI should
# be run prior to running this script to define various environment
# variables

# Parameters:
#  $1 - node index for this kafka node - as this node type may be horizontally scaled, should start at 0.

set -e

cat >> /etc/salt/grains <<EOF
roles:
  - kafka
  - kafka_tool
broker_id: $1
EOF

cat >> /etc/salt/grains <<EOF
vlans:
  pnda: $PNDA_INTERNAL_NETWORK
  ingest: $PNDA_INGEST_NETWORK
EOF

cat >> /etc/salt/minion <<EOF
id: $PNDA_CLUSTER-kafka-$1
EOF

DISTRO=$(cat /etc/*-release|grep ^ID\=|awk -F\= {'print $2'}|sed s/\"//g)
if [ "x$DISTRO" == "xubuntu" ]; then

cat > /etc/network/interfaces.d/$PNDA_INGEST_NETWORK.cfg <<EOF
auto $PNDA_INGEST_NETWORK
iface $PNDA_INGEST_NETWORK inet dhcp
EOF

elif [ "x$DISTRO" == "xrhel" ]; then

cat > /etc/sysconfig/network-scripts/ifcfg-$PNDA_INGEST_NETWORK <<EOF
DEVICE="$PNDA_INGEST_NETWORK"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
EOF

fi

ifup $PNDA_INGEST_NETWORK

echo $PNDA_CLUSTER-kafka-$1 > /etc/hostname
hostname $PNDA_CLUSTER-kafka-$1

service salt-minion restart
