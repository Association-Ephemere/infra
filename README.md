# Infra — Photo Stand

## 1. Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et démarré

## 2. Lancer le Compose

```bash
cd infra
docker compose up -d --build
```

Services exposés :

| Service     | URL / Port                          |
|-------------|-------------------------------------|
| Frontend    | http://photostand.local/            |
| API         | http://photostand.local/api         |
| Traefik     | http://localhost:8081/dashboard/    |
| RabbitMQ UI | http://localhost:15672              |
| MinIO       | http://localhost:9001               |
| PostgreSQL  | localhost:5432                      |

> Le service `frontend` est commenté dans le Compose. Décommenter quand le container est prêt.

## 3. Configurer mDNS

Lancer PowerShell **en administrateur** :

```powershell
.\scripts\setup-mdns.ps1
```

Cela ajoute `photostand.local` pointant vers l'IP locale du PC dans le fichier hosts.

## 4. Configurer pglogical (réplication bidirectionnelle)

> Prérequis : les migrations doivent avoir été appliquées sur les deux PCs avant de lancer ces scripts.

Éditer les scripts pour remplacer `PRIMARY_IP` (IP de PC A) et `SECONDARY_IP` (IP de PC B).

**Sur PC A :**

```bash
docker exec -i postgres psql -U root -d photostand < scripts/init-primary.sql
```

**Sur PC B :**

```bash
docker exec -i postgres psql -U root -d photostand < scripts/init-secondary.sql
```

Puis, une fois PC B initialisé, relancer la partie souscription sur PC A (la ligne `pglogical.create_subscription` dans `init-primary.sql`).

### Mode standalone

Le Compose fonctionne sans pglogical. Les scripts de réplication sont optionnels et n'affectent pas le démarrage.
