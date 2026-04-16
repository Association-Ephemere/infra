#!/bin/sh
export PGPASSWORD=root
PSQL="psql -h postgres -U root -d photostand"

if [ -z "${PEER_IP}" ]; then
    echo "PEER_IP not set — skipping pglogical setup."
    exit 0
fi

if [ -z "${MY_IP}" ]; then
    echo "ERROR: PEER_IP is set but MY_IP is empty. Check your .env file." >&2
    exit 1
fi

# Wait for job-svc migrations (tables must exist before pglogical can replicate them)
echo "Waiting for schema..."
until $PSQL -c "SELECT 1 FROM jobs LIMIT 1" > /dev/null 2>&1; do sleep 3; done
echo "Schema ready."

# Idempotent: skip node creation if already done
NODE_COUNT=$($PSQL -t -c "SELECT COUNT(*) FROM pglogical.node" 2>/dev/null | tr -d ' ' || echo "0")
if [ "${NODE_COUNT}" = "0" ]; then
    echo "Creating pglogical node..."
    $PSQL -c "CREATE EXTENSION IF NOT EXISTS pglogical;"

    if [ "${STAND_ROLE:-primary}" = "primary" ]; then
        $PSQL -c "SELECT pglogical.create_node(
            node_name := 'node_primary',
            dsn := 'host=${MY_IP} port=5432 dbname=photostand user=root password=root'
        );"
    else
        $PSQL -c "SELECT pglogical.create_node(
            node_name := 'node_secondary',
            dsn := 'host=${MY_IP} port=5432 dbname=photostand user=root password=root'
        );"
    fi

    $PSQL -c "SELECT pglogical.replication_set_add_table('default', 'jobs',       synchronize_data := true);"
    $PSQL -c "SELECT pglogical.replication_set_add_table('default', 'job_photos', synchronize_data := true);"
    echo "Node created."
fi

# Idempotent: skip subscription if already done
SUB_COUNT=$($PSQL -t -c "SELECT COUNT(*) FROM pglogical.subscription" 2>/dev/null | tr -d ' ' || echo "0")
if [ "${SUB_COUNT}" != "0" ]; then
    echo "Subscription already exists — done."
    exit 0
fi

# Wait for peer node to be ready
echo "Waiting for peer pglogical node at ${PEER_IP}..."
until PGPASSWORD=root psql -h "${PEER_IP}" -p 5432 -U root -d photostand \
    -c "SELECT 1 FROM pglogical.node LIMIT 1" > /dev/null 2>&1; do
    sleep 5
done
echo "Peer ready."

echo "Creating subscription..."
if [ "${STAND_ROLE:-primary}" = "primary" ]; then
    $PSQL -c "SELECT pglogical.create_subscription(
        subscription_name   := 'sub_secondary',
        provider_dsn        := 'host=${PEER_IP} port=5432 dbname=photostand user=root password=root',
        replication_sets    := ARRAY['default'],
        synchronize_structure := false,
        synchronize_data    := false
    );"
else
    $PSQL -c "SELECT pglogical.create_subscription(
        subscription_name   := 'sub_primary',
        provider_dsn        := 'host=${PEER_IP} port=5432 dbname=photostand user=root password=root',
        replication_sets    := ARRAY['default'],
        synchronize_structure := false,
        synchronize_data    := true
    );"
fi

echo "pglogical setup complete."
