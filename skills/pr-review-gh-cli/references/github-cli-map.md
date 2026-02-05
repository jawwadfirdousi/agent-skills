# GitHub CLI Mapping

Use these mappings for PR review workflows with GitHub CLI.

## Read-Only Policy

- Treat this workflow as read-only.
- Use only read/list/view/search/diff/check operations.
- Enable the read-only shell environment first: `source "<SKILL_DIR>/scripts/activate-gh-readonly.sh"`.
- After sourcing, call `gh` normally; it is intercepted by the read-only wrapper.
- Do not run mutating operations (`edit`, `comment`, `review`, `merge`, or `gh api` with `POST/PATCH/PUT/DELETE`).

## Prerequisites

- Confirm auth: `gh auth status`
- Resolve repository context:
  - Preferred: run inside the repository root.
  - Alternative: add `-R <owner>/<repo>` to commands.

## Backend Review Operation Mapping

| Allowed operation | GitHub CLI equivalent |
| --- | --- |
| `search_code` | `gh search code "<query>"` |
| `get_commit` | `gh api repos/<OWNER>/<REPO>/commits/<SHA>` |
| `get_file_contents` | `gh api repos/<OWNER>/<REPO>/contents/<PATH>?ref=<REF>` (content is usually base64 in `.content`) |
| `get_issue` | `gh issue view <ISSUE_NUMBER> [--comments] [--json <fields>]` |
| `get_me` | `gh api user` |
| `get_pull_request` | `gh pr view <PR_NUMBER> [--json <fields>]` |
| `get_pull_request_comments` | PR conversation comments: `gh pr view <PR_NUMBER> --comments`; issue comments API: `gh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments --paginate`; inline review comments: `gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments --paginate` |
| `get_pull_request_diff` | `gh pr diff <PR_NUMBER> [--patch|--name-only]` |
| `get_pull_request_files` | `gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/files --paginate` |
| `get_pull_request_reviews` | `gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/reviews --paginate` |
| `get_pull_request_status` | `gh pr checks <PR_NUMBER> [--json <fields>]` |
| `list_commits` | `gh api repos/<OWNER>/<REPO>/commits --paginate` |
| `list_pull_requests` | `gh pr list [flags]` |
| `search_issues` | `gh search issues "<query>"` |

## Notes

- Prefer `gh pr view --json ...` and `gh pr checks --json ...` when structured output is needed.
- Prefer `gh api` when no first-class subcommand exists.
- Use `--paginate` for list endpoints when full history matters.
- Keep requests scoped to required fields to reduce noise.
- If asked to post review comments or change PR state, refuse and keep the process read-only.
