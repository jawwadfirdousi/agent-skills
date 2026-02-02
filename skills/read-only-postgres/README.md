# read-only-postgres

Read-only PostgreSQL query skill. Query multiple databases safely with write protection.

## Setup

1. Copy the example config:
```bash
cp connections.example.json connections.json
```

2. Add your database credentials:
```json
{
  "databases": [
    {
      "name": "prod",
      "description": "Production - users, orders, transactions",
      "host": "db.example.com",
      "port": 5432,
      "database": "app_prod",
      "user": "readonly",
      "password": "secret",
      "sslmode": "require"
    }
  ]
}
```

3. Secure the config:
```bash
chmod 600 connections.json
```

4. Prompt to Update the `SKILL.md` file to be specific to your project.
```text
Make the read-only-postgres skill examples specific to this project.

Steps:
1) Scan the repo for database schema sources (migrations, ORM models, schema.sql, db/ folders).
2) Identify 4-5 core domains (e.g., users, orders, invoices, audit logs) and any key tables.
3) Update skills/read-only-postgres/SKILL.md to:
   - Replace the sample connections.json database names/descriptions with project-specific ones.
   - Update the example queries to use real tables/columns from the codebase.
   - Update the database-selection mapping table to match the project’s domains.
4) Keep everything read-only and avoid adding real credentials.

Return a brief summary of the changes and the files edited.
```

## Usage

```bash
# List configured databases
python3 scripts/query.py --list

# List tables
python3 scripts/query.py --db prod --tables

# Show schema
python3 scripts/query.py --db prod --schema

# Run query
python3 scripts/query.py --db prod --query "SELECT * FROM users" --limit 100
```

## Config Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| name | Yes | - | Database identifier |
| description | Yes | - | What data it contains (for auto-selection) |
| host | Yes | - | Hostname |
| port | No | 5432 | Port |
| database | Yes | - | Database name |
| user | Yes | - | Username |
| password | Yes | - | Password |
| sslmode | No | prefer | disable, allow, prefer, require, verify-ca, verify-full |

## Safety Features

- **Read-only sessions**: PostgreSQL `readonly=True` mode blocks writes at database level
- **Query validation**: Only SELECT, SHOW, EXPLAIN, WITH allowed
- **Single statement**: No multi-statement queries (prevents `SELECT 1; DROP TABLE`)
- **Timeouts**: 30s query timeout, 10s connection timeout
- **Memory cap**: Max 10,000 rows per query
- **Credential protection**: Passwords sanitized from error messages

## Requirements

```bash
pip install psycopg2-binary
```
