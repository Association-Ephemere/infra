#!/usr/bin/env bash
# setup-mdns.sh — configure photostand.local et subdomains sur Linux
# Usage : sudo ./setup-mdns.sh

set -e

DOMAINS=(
    photostand.local
    minio.photostand.local
    rabbitmq.photostand.local
    pgadmin.photostand.local
    postgres.photostand.local
    traefik.photostand.local
    s3.photostand.local
)

HOSTS_FILE="/etc/hosts"

LOCAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')

if [ -z "$LOCAL_IP" ]; then
    echo "Impossible de detecter l'IP locale." >&2
    exit 1
fi

# Supprimer les anciennes entrées photostand
sed -i '/photostand\.local/d' "$HOSTS_FILE"

# Ajouter tous les domaines sur une ligne
echo "$LOCAL_IP	${DOMAINS[*]}" >> "$HOSTS_FILE"

echo "OK : $LOCAL_IP  ${DOMAINS[*]}"
