# GSP355 Cloud SQL PostgreSQL Challenge Lab

Clone:

```bash
git clone https://github.com/harinish45/cloudarcadesolutions.git
cd cloudarcadesolutions/labs/gsp355-cloudsql-postgresql-challenge-lab
bash setup.sh
```

The helper is tailored to the current values supplied for this GSP355 session:

- Region: `us-central1`
- Cloud SQL instance: `postgres83-psvr9`
- Source VM: `postgres-vm`
- Source database: `orders`
- Migration user: `import_admin`
- IAM user: `student-01-14865d1bb956@qwiklabs.net`
- IAM-protected table: `inventory_items`
- PITR retention: 5 days
- PITR clone: `postgres-orders-pitr`

`setup.sh` automates source PostgreSQL preparation, pglogical, replication settings, primary-key checks, migration-user privileges, DMS VPC-peering connectivity, connection profiles, and the continuous migration job.

After the migration reaches the state required for promotion, run:

```bash
bash finish.sh
```

That handles promotion, IAM database authentication, the authorized network, the table SELECT grant, PITR configuration, the required data change, and the PITR clone.

Passwords are requested at runtime and are not stored in this repository.
