# GitHub CLI Mapping

Use these mappings for PR review workflows with GitHub CLI.

## Read-Only Policy

- Treat this workflow as read-only.
- Use only read/list/view/search/diff/check operations.
- Run all commands through `scripts/gh-readonly.sh`.
- Resolve `scripts/gh-readonly.sh` relative to the skill directory.
- Do not call `gh` directly for review workflows.
- Do not run mutating operations (`edit`, `comment`, `review`, `merge`, or `gh api` with `POST/PATCH/PUT/DELETE`).

## Prerequisites

- Confirm auth: `scripts/gh-readonly.sh auth status`
- Resolve repository context:
  - Preferred: run inside the repository root.
  - Alternative: add `-R <owner>/<repo>` to commands.

## Backend Review Operation Mapping

| Allowed operation | GitHub CLI equivalent |
| --- | --- |
| `search_code` | `scripts/gh-readonly.sh search code "<query>"` |
| `get_commit` | `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/commits/<SHA>` |
| `get_file_contents` | `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/contents/<PATH>?ref=<REF>` (content is usually base64 in `.content`) |
| `get_issue` | `scripts/gh-readonly.sh issue view <ISSUE_NUMBER> [--comments] [--json <fields>]` |
| `get_me` | `scripts/gh-readonly.sh api user` |
| `get_pull_request` | `scripts/gh-readonly.sh pr view <PR_NUMBER> [--json <fields>]` |
| `get_pull_request_comments` | PR conversation comments: `scripts/gh-readonly.sh pr view <PR_NUMBER> --comments`; issue comments API: `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments --paginate`; inline review comments: `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments --paginate` |
| `get_pull_request_diff` | `scripts/gh-readonly.sh pr diff <PR_NUMBER> [--patch|--name-only]` |
| `get_pull_request_files` | `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/files --paginate` |
| `get_pull_request_reviews` | `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/reviews --paginate` |
| `get_pull_request_status` | `scripts/gh-readonly.sh pr checks <PR_NUMBER> [--json <fields>]` |
| `list_commits` | `scripts/gh-readonly.sh api repos/<OWNER>/<REPO>/commits --paginate` |
| `list_pull_requests` | `scripts/gh-readonly.sh pr list [flags]` |
| `search_issues` | `scripts/gh-readonly.sh search issues "<query>"` |

## Notes

- Prefer `scripts/gh-readonly.sh pr view --json ...` and `scripts/gh-readonly.sh pr checks --json ...` when structured output is needed.
- Prefer `scripts/gh-readonly.sh api` when no first-class subcommand exists.
- Use `--paginate` for list endpoints when full history matters.
- Keep requests scoped to required fields to reduce noise.
- If asked to post review comments or change PR state, refuse and keep the process read-only.
