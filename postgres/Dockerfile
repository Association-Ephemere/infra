FROM postgres:16
RUN apt-get update && apt-get install -y postgresql-16-pglogical && rm -rf /var/lib/apt/lists/*
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
