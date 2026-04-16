# Setup — Double PC

Les deux PCs doivent être sur le même réseau local.

## Prérequis (sur chaque PC)

- Docker + Docker Compose
- .NET 8 SDK (pour build print-svc)
- Git
- Windows 10/11

---

## 1. Cloner le dépôt (sur chaque PC)

```powershell
git clone <repo-url>
cd Stand/infra
```

---

## 2. Configurer les domaines locaux (sur chaque PC)

PowerShell en **administrateur** :

```powershell
.\scripts\setup-mdns.ps1
```

---

## 3. Créer le fichier `.env` (sur chaque PC)

```powershell
Copy-Item .env.example .env
```

Éditer `.env` :

**PC A** :
```env
STAND_ID=stand-a
STAND_ROLE=primary
MY_IP=192.168.1.100
PEER_IP=192.168.1.101
ERLANG_COOKIE=photostand-cluster-secret
```

**PC B** :
```env
STAND_ID=stand-b
STAND_ROLE=secondary
MY_IP=192.168.1.101
PEER_IP=192.168.1.100
ERLANG_COOKIE=photostand-cluster-secret
```

> `ERLANG_COOKIE` doit être **identique** sur les deux PCs.
> Trouver son IP : `(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -eq "Dhcp" } | Select-Object -First 1).IPAddress`

---

## 4. Démarrer l'infrastructure Docker (sur les deux PCs en même temps)

```powershell
docker compose up -d
```

Démarrer les deux PCs **simultanément** pour que le cluster RabbitMQ se forme avant la création des queues.
Attendre ~90s au premier démarrage.

```powershell
docker compose ps   # tous les services doivent être healthy
```

---

## 5. Installer et démarrer print-svc (sur chaque PC)

### Build

```powershell
cd ..\print-svc
dotnet publish src/PrintSvc -c Release -r win-x64 --self-contained -o .\publish
```

### Configurer

Créer `.\publish\appsettings.local.json` (depuis `print-svc\`) sur chaque PC :

```json
{
  "Broker": {
    "Host": "rabbitmq.photostand.local",
    "Port": 5672,
    "Username": "guest",
    "Password": "guest",
    "JobsQueue": "print.jobs",
    "ResultsQueue": "print.status"
  },
  "Storage": {
    "Endpoint": "s3.photostand.local",
    "AccessKey": "minioadmin",
    "SecretKey": "minioadmin",
    "Bucket": "photostand",
    "UseSSL": false
  },
  "Printing": {
    "PrinterName": "",
    "PaperWidthInches": 6.0,
    "PaperHeightInches": 4.0
  }
}
```

> `PrinterName` vide = imprimante système par défaut.
> Pour lister les imprimantes disponibles : `Get-Printer | Select-Object Name`

### Installer comme service Windows

PowerShell en **administrateur** :

```powershell
$path = (Resolve-Path ".\publish\PrintSvc.exe").Path
sc.exe create PrintSvc binPath="$path" start=auto
sc.exe start PrintSvc
```

---

## 6. Vérifier

### Infrastructure

```powershell
docker compose ps
```

### Cluster RabbitMQ

```powershell
docker exec rabbitmq rabbitmqctl cluster_status
```

Les deux nœuds (`rabbit@192.168.1.100` et `rabbit@192.168.1.101`) doivent apparaître.

### Réplication pglogical

```powershell
docker exec postgres psql -U root -d photostand -c "SELECT subscription_name, status FROM pglogical.show_subscription_status();"
```

Le statut doit être `replicating`.

### Réplication MinIO

```powershell
docker logs minio-replicate
```

### print-svc

```powershell
sc.exe query PrintSvc   # STATE doit être RUNNING
```

---

## Volumes locaux

Chaque PC a **uniquement ses propres volumes** :

```
infra/volumes/
  db/                    ← données Postgres de ce PC
  capture/
    stand-a/             ← sur PC A uniquement
      watch/             ← déposer les photos ici
      processed/
      failed/
```

La synchronisation inter-PC est applicative (pglogical, MinIO replication, RabbitMQ cluster).

---

## URLs

Identiques sur les deux PCs :

| Service           | URL                              |
|-------------------|----------------------------------|
| Frontend          | http://photostand.local          |
| API               | http://photostand.local/api      |
| RabbitMQ          | http://rabbitmq.photostand.local |
| MinIO console     | http://minio.photostand.local    |
| pgAdmin           | http://pgadmin.photostand.local  |
| Traefik dashboard | http://traefik.photostand.local  |

---

## Arrêter

```powershell
sc.exe stop PrintSvc
docker compose down   # sur chaque PC
```

> Pour tout réinitialiser : `docker compose down -v` **puis** supprimer `volumes/db/` et `volumes/capture/`. La réplication pglogical sera reconfigurée automatiquement au prochain démarrage.
