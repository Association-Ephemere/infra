# Infra — Notes

## URLs

| Service           | URL                                    |
|-------------------|----------------------------------------|
| Frontend          | http://photostand.local                |
| API (job-svc)     | http://photostand.local/api            |
| MinIO console     | http://minio.photostand.local          |
| MinIO S3 API      | http://s3.photostand.local             |
| RabbitMQ          | http://rabbitmq.photostand.local       |
| pgAdmin           | http://pgadmin.photostand.local        |
| Traefik dashboard | http://traefik.photostand.local        |
| Postgres TCP      | postgres.photostand.local:5432         |

## Ports

| Service    | Port  | Protocole | Accès                  |
|------------|-------|-----------|------------------------|
| Traefik    | 80    | HTTP      | public                 |
| Traefik    | 5432  | TCP       | public                 |
| Traefik    | 5672  | TCP       | public (AMQP)          |
| Traefik    | 8082  | HTTP      | localhost              |
| Postgres   | 5432  | TCP       | via Traefik            |
| RabbitMQ   | 5672  | AMQP      | via Traefik            |
| RabbitMQ   | 15672 | HTTP      | via Traefik            |
| RabbitMQ   | 4369  | TCP       | public (duo — epmd)    |
| RabbitMQ   | 25672 | TCP       | public (duo — cluster) |
| MinIO      | 9000  | HTTP      | public (S3 API)        |
| MinIO      | 9001  | HTTP      | via Traefik            |
| job-svc    | 8080  | HTTP      | via Traefik            |
| frontend   | 80    | HTTP      | via Traefik            |
| pgAdmin    | 80    | HTTP      | via Traefik            |

## Credentials

| Service    | User               | Password    | Extra                  |
|------------|--------------------|-------------|------------------------|
| Postgres   | root               | root        | db: photostand         |
| RabbitMQ   | guest              | guest       | vhost: /               |
| MinIO      | minioadmin         | minioadmin  | bucket: photostand     |
| pgAdmin    | admin@admin.com    | admin       |                        |
