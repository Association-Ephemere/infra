#!/bin/sh
if [ -z "${PEER_IP}" ]; then
    echo "PEER_IP not set — skipping MinIO replication setup."
    exit 0
fi

if [ "${STAND_ROLE:-primary}" != "primary" ]; then
    echo "Secondary node — site replication configured by primary."
    exit 0
fi

mc alias set local "http://${MY_IP}:9000" minioadmin minioadmin

mc alias set peer "http://${PEER_IP}:9000" minioadmin minioadmin

echo "Waiting for peer MinIO admin API at ${PEER_IP}:9000..."
until mc admin info peer > /dev/null 2>&1; do
    sleep 5
done

# Remove peer bucket so only primary has data (required by site replication)
mc rb --force peer/photostand 2>/dev/null || true

# Site-level replication — replicates all buckets automatically
mc admin replicate add local peer

echo "MinIO replication setup complete."
