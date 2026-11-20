# Terraform + Database Reliability

A hands-on DevOps assessment demonstrating Terraform planning for AWS and a reproducible local PostgreSQL workflow using Docker Compose.

**Scope:** Terraform configuration and plans for dev/prod, database schema and seed scripts, indexes/query analysis, and backup/restore testing. **No AWS resources were deployed.** Plans were generated in an assessment-only context using dummy credentials and validation-oriented provider settings.

## Contents
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Database operations](#database-operations)
- [Query analysis](#query-analysis)
- [Backup and restore](#backup-and-restore)
- [Terraform checks](#terraform-checks)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)

## Architecture

### AWS design (Terraform)
The Terraform configuration describes:
- VPC with public and private subnets
- Application Load Balancer (ALB)
- ECS Fargate workloads
- Private RDS PostgreSQL
- Separate dev and prod environment configurations

This design was validated and planned locally, not deployed.

### Local database
Docker Compose runs PostgreSQL 16 in a container named `hotel-postgres`, with a database named `hotelbooking`. The SQL scripts create `hotel_bookings` and `booking_events`, load example data, and add indexes.

## Prerequisites
- Git
- Docker Desktop with Docker Compose (Windows users: WSL2 Ubuntu with Docker Desktop WSL integration recommended)
- Terraform for infrastructure checks
- PostgreSQL client utilities are optional; scripts use tools in the container where appropriate

On Windows/WSL, a D: drive project path is available as:
```bash
cd /mnt/d/terraform-db-assessment
```

## Quick start

### 1. Clone
```bash
git clone <YOUR_REPOSITORY_URL>
cd terraform-db-assessment
```
If already cloned, simply enter the project directory.

### 2. Start PostgreSQL
```bash
docker compose up -d
docker compose ps
```

### 3. Apply migration
From the repository root:
```bash
docker exec -i hotel-postgres psql -U postgres -d hotelbooking < database/migrations/001_create_tables.sql
```

### 4. Load seed data
```bash
docker exec -i hotel-postgres psql -U postgres -d hotelbooking < database/seed/001_seed_data.sql
```
The seed script may not be idempotent; running it more than once can add additional rows.

### 5. Create indexes
```bash
docker exec -i hotel-postgres psql -U postgres -d hotelbooking < database/optimization/001_indexes.sql
```

### 6. Connect and inspect
```bash
docker exec -it hotel-postgres psql -U postgres -d hotelbooking
```
Inside `psql`:
```sql
\dt
\d hotel_bookings
\d booking_events
SELECT COUNT(*) FROM hotel_bookings;
SELECT COUNT(*) FROM booking_events;
\q
```

## Database operations

### Schema
| Table | Description |
|---|---|
| `hotel_bookings` | Booking details, organization, hotel, city, dates, amount, status, timestamp |
| `booking_events` | Booking-related event records, JSON payload, timestamp, and foreign key |

### Query analysis
Connect to the database, then run:
```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Use `EXPLAIN ANALYZE` to inspect actual execution:
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```
Compare execution plans before and after indexes using the same query and data. `EXPLAIN ANALYZE` executes the query.

### Indexes
Apply the index script:
```bash
docker exec -i hotel-postgres psql -U postgres -d hotelbooking < database/optimization/001_indexes.sql
```
Inspect indexes:
```sql
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'hotel_bookings';
```

## Backup and restore

### Create a backup
From the repository root:
```bash
./scripts/backup.sh
```
Or from `scripts/`:
```bash
./backup.sh
```
Backups are saved under `backups/`. The backup script uses `pg_dump` inside the PostgreSQL container to avoid host/container utility version mismatches.

### Restore
From the repository root:
```bash
./scripts/restore.sh
```
Or from `scripts/`:
```bash
./restore.sh
```
By default, the restore script recreates a separate target database named `hotelbooking_restore` and restores the latest dump into it.

**Warning:** The script drops and recreates its target database. Confirm the `RESTORE_DB` setting before use in any environment with important data.

### Verify
```bash
docker exec -it hotel-postgres psql -U postgres -d hotelbooking_restore
```
Run:
```sql
SELECT COUNT(*) FROM hotel_bookings;
SELECT COUNT(*) FROM booking_events;
\q
```
Compare with the source:
```bash
docker exec hotel-postgres psql -U postgres -d hotelbooking -c "SELECT COUNT(*) FROM hotel_bookings;"
docker exec hotel-postgres psql -U postgres -d hotelbooking -c "SELECT COUNT(*) FROM booking_events;"
```
Successful restoration should reproduce the source data. Counts may exceed initial seed expectations if seed scripts were run more than once.

Do not commit backup dumps; they may contain sensitive data.

## Terraform checks

For each environment's Terraform directory:
```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```
If the environment requires a variable file:
```bash
terraform plan -var-file="dev.tfvars"
```
Use the corresponding production variable file for prod.

The assessment dev and prod plans were generated successfully at the time of testing, showing resources planned for creation without changes or destructions. Plans are not proof of successful AWS provisioning.

**Do not run `terraform apply` using dummy credentials or assessment-only provider settings.**

## Security notes
- Never commit AWS credentials, secrets, private keys, Terraform state, or database dumps.
- Use secret management and least-privilege IAM in real deployments.
- Separate dev/prod state and access controls.
- Review security groups, routing, encryption, monitoring, backup retention, and secret handling before real AWS deployment.
- Local credentials are for development only.

## Troubleshooting

**Container is not running:**
```bash
docker compose up -d
docker compose ps
docker logs hotel-postgres
```

**Connect directly to the database:**
```bash
docker exec -it hotel-postgres psql -U postgres -d hotelbooking
```

**Restore dump-version mismatch:** Use compatible PostgreSQL tools. This project's backup script invokes `pg_dump` inside the container.

**Terraform checks:**
```bash
terraform version
terraform fmt -recursive
terraform validate
```

## Assessment status

| Task | Status |
|---|---|
| Terraform dev plan | Completed |
| Terraform prod plan | Completed |
| Docker PostgreSQL | Completed |
| Migrations | Completed |
| Seed data | Completed |
| Indexes | Completed |
| Query/execution-plan analysis | Performed |
| Backup | Completed |
| Restore test | Completed |
| README | Documented |
| GitHub publication | Pending |

## Scope and limitations
This repository demonstrates Terraform design, validation/planning, SQL operations, and database backup/restore in a local environment. **AWS deployment was not performed.** Terraform plans represent planning results only, not a live infrastructure deployment.
