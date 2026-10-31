# GSP355: Cloud SQL PostgreSQL Challenge Lab — Technical Notes & Deep Dive

## 🔍 Core Concepts

### 1. Database Migration Service (DMS) with PostgreSQL
Google Cloud Database Migration Service provides serverless, minimal-downtime database migrations into Cloud SQL for PostgreSQL.
- **Initial Dump & Load**: Transfers existing data tables, schemas, and indices.
- **Continuous Change Data Capture (CDC)**: Relies on `pglogical` extension on PostgreSQL 10+ or native logical decoding to replicate ongoing transactional writes.
- **Private Connectivity**: Established via VPC Peering or Reverse SSH tunnel. In this challenge lab, a dedicated `/29` subnet is allocated for the DMS private connection.

### 2. Required PostgreSQL Configuration on Source VM
For logical replication to operate without failures:
```ini
shared_preload_libraries = 'pglogical'
wal_level = 'logical'
max_replication_slots = 10
max_wal_senders = 10
max_worker_processes = 10
```
Every replicated table MUST have a defined `PRIMARY KEY`. Tables without a primary key will fail replication in pglogical unless `REPLICA IDENTITY FULL` is configured.

### 3. Cloud SQL IAM Database Authentication
- Cloud SQL supports mapping IAM users directly to database roles without maintaining static SQL user passwords.
- Instance flag `cloudsql.iam_authentication=on` is mandatory.
- User email format: `student-xx-xxxx@qwiklabs.net` is registered as `cloud_iam_user`.
- IAM Role `roles/cloudsql.instanceUser` allows the identity to log into the database.
- Database privilege `GRANT SELECT ON <table> TO "<iam_user>"` must be explicitly executed inside PostgreSQL.

### 4. Point-In-Time Recovery (PITR) & Transaction Log Retention
- PITR enables recovering an instance to any second within the retention window.
- Prerequisite: Automated backups must be active.
- Flag `--enable-point-in-time-recovery` combined with `--retained-transaction-log-days=5` allows cloning the database precisely before an unwanted mutation.
- Clone operation: `gcloud sql instances clone <source> <target> --point-in-time=<ISO-8601-UTC-TIMESTAMP>`.

## ⚠️ Common Pitfalls & Solutions

| Issue | Cause | Fix |
|---|---|---|
| `pglogical extension missing` | Package not installed on Debian VM | `apt-get install -y postgresql-14-pglogical` and restart service |
| `Tables missing Primary Keys` | DMS pre-check fails validation | Run script block to add `PRIMARY KEY (id)` to all tables |
| `Cannot connect via IAM` | Flag not activated or role not granted | Enable `cloudsql.iam_authentication=on` and assign `roles/cloudsql.instanceUser` |
| `PITR clone fails` | Selected timestamp is in the future or before backup start | Ensure timestamp is formatted in UTC (e.g., `date -u '+%Y-%m-%dT%H:%M:%S.%3NZ'`) |
