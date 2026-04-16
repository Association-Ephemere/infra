# Setup — PC unique

## Prérequis

- Docker + Docker Compose
- .NET 8 SDK (pour build print-svc)
- Git
- Windows 10/11

---

## 1. Cloner le dépôt

```powershell
git clone <repo-url>
cd Stand/infra
```

---

## 2. Configurer les domaines locaux

PowerShell en **administrateur** :

```powershell
.\scripts\setup-mdns.ps1
```

Ajoute `photostand.local` et ses sous-domaines dans le fichier hosts Windows.

---

## 3. Démarrer l'infrastructure Docker

```powershell
docker compose up -d
```

Pas de `.env` nécessaire — les valeurs par défaut s'appliquent (`STAND_ID=stand-a`).
Attendre ~60s au premier démarrage (builds + healthchecks).

```powershell
docker compose ps   # tous les services doivent être healthy
```

---

## 4. Installer et démarrer print-svc

### Build

```powershell
cd ..\print-svc
dotnet publish src/PrintSvc -c Release -r win-x64 --self-contained -o .\publish
```

### Configurer

Créer `.\publish\appsettings.local.json` (depuis `print-svc\`) :

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

### Vérifier

```powershell
sc.exe query PrintSvc   # STATE doit être RUNNING
```

---

## URLs

| Service           | URL                              |
|-------------------|----------------------------------|
| Frontend          | http://photostand.local          |
| API               | http://photostand.local/api      |
| RabbitMQ          | http://rabbitmq.photostand.local |
| MinIO console     | http://minio.photostand.local    |
| pgAdmin           | http://pgadmin.photostand.local  |
| Traefik dashboard | http://traefik.photostand.local  |

## Credentials

| Service  | Utilisateur     | Mot de passe |
|----------|-----------------|--------------|
| Postgres | root            | root         |
| RabbitMQ | guest           | guest        |
| MinIO    | minioadmin      | minioadmin   |
| pgAdmin  | admin@admin.com | admin        |

---

## Volumes locaux

```
infra/volumes/
  db/                    ← données Postgres
  capture/
    stand-a/
      watch/             ← déposer les photos ici
      processed/
      failed/
```

---

## Arrêter

```powershell
sc.exe stop PrintSvc
docker compose down
```

> Les données sont conservées dans `volumes/`. Pour tout réinitialiser : `docker compose down -v` **puis** supprimer `volumes/db/` et `volumes/capture/`.
