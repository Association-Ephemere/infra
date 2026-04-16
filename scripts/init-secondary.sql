-- init-secondary.sql — exécuter sur PC B
-- Prérequis : les tables `jobs` et `job_photos` doivent exister (migrations appliquées)
-- Remplacer PRIMARY_IP et SECONDARY_IP par les IPs réelles

\c photostand

CREATE EXTENSION IF NOT EXISTS pglogical;

-- Nœud provider sur PC B
SELECT pglogical.create_node(
    node_name := 'node_secondary',
    dsn       := 'host=SECONDARY_IP port=5432 dbname=photostand user=root password=root'
);

-- Ajouter les tables au replication set par défaut
SELECT pglogical.replication_set_add_table('default', 'jobs',       synchronize_data := true);
SELECT pglogical.replication_set_add_table('default', 'job_photos', synchronize_data := true);

-- Souscription à PC A
SELECT pglogical.create_subscription(
    subscription_name   := 'sub_primary',
    provider_dsn        := 'host=PRIMARY_IP port=5432 dbname=photostand user=root password=root',
    replication_sets    := ARRAY['default'],
    synchronize_structure := false,
    synchronize_data    := true
);
