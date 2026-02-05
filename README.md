# agent-skills

Reusable skill definitions.

## Available skills

- `read-only-postgres`: Run safe, read-only PostgreSQL queries.
- `read-only-gh-pr-review`: Review GitHub PRs using the gh CLI (read-only).

## Symlink a skill into your project

If your project expects skills under `skills/` (adjust paths as needed):

```bash
ln -s /path/to/agent-skills/skills/read-only-postgres /path/to/your-project/skills/read-only-postgres
ln -s /path/to/agent-skills/skills/read-only-gh-pr-review /path/to/your-project/skills/read-only-gh-pr-review
```
