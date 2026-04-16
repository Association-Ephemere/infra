#Requires -RunAsAdministrator
# setup-mdns.ps1 — configure photostand.local et subdomains dans le fichier hosts Windows

$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$domains = @(
    "photostand.local",
    "minio.photostand.local",
    "rabbitmq.photostand.local",
    "pgadmin.photostand.local",
    "postgres.photostand.local",
    "traefik.photostand.local",
    "s3.photostand.local"
)

# Détecte l'IP locale (première interface DHCP, hors loopback)
$localIp = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -eq "Dhcp" } |
    Select-Object -First 1).IPAddress

if (-not $localIp) {
    Write-Error "Impossible de détecter l'IP locale."
    exit 1
}

$entry = "$localIp`t" + ($domains -join "`t")

# Supprime les anciennes entrées photostand
$lines = Get-Content $hostsFile | Where-Object { $_ -notmatch "photostand\.local" }

# Ajoute la nouvelle entrée
$lines += $entry
$lines | Set-Content $hostsFile -Encoding UTF8

Write-Host "OK : $entry ajouté dans $hostsFile"
