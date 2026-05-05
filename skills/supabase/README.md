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

Copy the template and fill in your credentials:

```bash
cp skills/supabase/env/example.env.template skills/supabase/env/my-project-dev.env
$EDITOR skills/supabase/env/my-project-dev.env
```

The filename must follow `<project>-<env>.env`. Examples:

- `skills/supabase/env/my-project-dev.env`
- `skills/supabase/env/my-project-prod.env`

Required variables (also documented inline in the template):

```bash
SUPABASE_URL="https://<project-ref>.supabase.co"
SUPABASE_ACCESS_TOKEN="sbp_<management_api_token>"
```

Everything in `skills/supabase/env/` except `example.env.template` is gitignored.
You can also export `SUPABASE_URL` and `SUPABASE_ACCESS_TOKEN` directly to bypass env files.

Env resolution order:

1. `--env-file <path>` loads that explicit file.
2. `--project <project> --env <name>` loads `skills/supabase/env/<project>-<name>.env`.
3. If `skills/supabase/env` contains exactly one `.env` file, that file is auto-loaded.
4. If `skills/supabase/env` contains multiple `.env` files, you must pass `--project` + `--env`, or `--env-file`.
5. If `skills/supabase/env` contains no `.env` files, the script falls back to legacy env discovery:
   - Explicit `SUPABASE_ENV_FILE`
   - `SUPABASE_ENV` as `.env.supabase.<name>`
   - `.env.supabase.admin`
   - `.env.supabase`

## How To Use It

Run raw SQL:

```bash
# Works without --project/--env only when skills/supabase/env has exactly one .env file
skills/supabase/scripts/supabase.sh sql "SELECT * FROM users LIMIT 5"
skills/supabase/scripts/supabase.sh sql --project my-project --env dev "SELECT * FROM users LIMIT 5"
skills/supabase/scripts/supabase.sh sql --project my-project --env prod "SELECT * FROM users LIMIT 5"
```

Run SQL from a file:

```bash
skills/supabase/scripts/supabase.sh sql-file ./migrations/001_init.sql
skills/supabase/scripts/supabase.sh sql-file --project my-project --env dev ./migrations/001_init.sql
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
