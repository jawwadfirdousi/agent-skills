# supabase

Supabase management skill for persistent data operations, SQL execution, schema changes, storage setup, and related admin workflows.

## What It Is

This skill wraps the Supabase management API behind a small shell script so an agent can run SQL or apply SQL files against a Supabase project. It is intended for tasks like querying data, creating or altering tables, defining policies, managing storage metadata, and handling other persistent-data work.

Because it uses management API access, treat it like admin-level database access.

## Requirements

- `bash`, `curl`, and `jq`
- A Supabase project URL
- A Supabase personal access token with management API access

## Setup

You can either export credentials directly or provide them through a repo-level env file.

Example env file:

```bash
cp skills/supabase/.env.supabase.example .env.supabase.admin
```

Then set:

```bash
SUPABASE_URL="https://your-project-ref.supabase.co"
SUPABASE_ACCESS_TOKEN="sbp_your_access_token"
```

The script will auto-load, in order:

- Explicit `SUPABASE_ENV_FILE`
- `SUPABASE_ENV` as `.env.supabase.<name>`
- `.env.supabase.admin`
- `.env.supabase`

## How To Use It

Run raw SQL:

```bash
skills/supabase/scripts/supabase.sh sql "SELECT * FROM users LIMIT 5"
```

Run SQL from a file:

```bash
skills/supabase/scripts/supabase.sh sql-file ./migrations/001_init.sql
```

## Common Uses

- Querying or debugging production-like data
- Creating tables, views, functions, triggers, and extensions
- Managing RLS policies
- Managing storage bucket metadata
- Applying migrations from SQL files

## Example Prompts

```text
Use the supabase skill to add a new table for invoice_exports and create the required RLS policies.
```

```text
Use the supabase skill to inspect the public schema and show me the columns on the users table.
```

## Notes

- `SKILL.md` contains a larger command reference with examples for DDL, RLS, storage, and introspection.
- The script derives the Supabase project ref from `SUPABASE_URL`.
- Keep tokens out of committed files.
