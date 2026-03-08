# agent-skills

[![Mentioned in Awesome Claude Code](https://awesome.re/mentioned-badge.svg)](https://github.com/hesreallyhim/awesome-claude-code)

Reusable skill definitions.

## Available skills

- `prompt-template-wizard`: Turn incomplete feature and bug requests into complete, paste-ready prompt templates.
- `read-only-gh-pr-review`: Review backend pull requests with GitHub CLI and local inspection in strict read-only mode.
- `read-only-postgres`: Run safe, read-only PostgreSQL queries against configured databases.
- `supabase`: Use Supabase for CRUD, SQL, migrations, storage, and vector search workflows.

This list reflects the skill definitions currently tracked in git under `skills/`.

## Symlink a skill into your project

If your project expects skills under `skills/` (adjust paths as needed), symlink the skill directory you want:

```bash
SKILL=read-only-postgres
ln -s "/path/to/agent-skills/skills/$SKILL" "/path/to/your-project/skills/$SKILL"
```

See each skill's `README.md` for a human overview and `SKILL.md` for the full skill instructions.
