#!/bin/sh
set -e

# Generate rabbitmq.conf — cluster formation if peer is configured
if [ -n "${MY_IP}" ] && [ -n "${PEER_IP}" ]; then
    cat > /etc/rabbitmq/rabbitmq.conf <<EOF
loopback_users = none
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit@${MY_IP}
cluster_formation.classic_config.nodes.2 = rabbit@${PEER_IP}
cluster_formation.node_cleanup.only_log_warning = true
EOF
    export RABBITMQ_USE_LONGNAME=true
    export RABBITMQ_NODENAME="rabbit@${MY_IP}"
else
    echo "loopback_users = none" > /etc/rabbitmq/rabbitmq.conf
fi

# RABBITMQ_ERLANG_COOKIE is handled by the official docker-entrypoint.sh
exec docker-entrypoint.sh rabbitmq-server "$@"
