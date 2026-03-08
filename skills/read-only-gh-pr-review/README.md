# read-only-gh-pr-review

Read-only backend pull request review skill built around GitHub CLI plus local repository inspection.

## What It Is

This skill reviews a pull request without mutating GitHub state. It enables a shell wrapper that intercepts `gh` commands and blocks write operations, then gathers PR metadata, diff context, checks, comments, and changed files for a risk-focused review.

It is designed for high-signal backend reviews where correctness, security, data integrity, API compatibility, performance, and test coverage matter more than style feedback.

## Requirements

- `gh` installed and available in `PATH`
- An authenticated GitHub session via `gh auth login`
- Network access

## How To Use It

1. Make the skill available under `skills/read-only-gh-pr-review`.
2. In the review shell session, enable the read-only wrapper:

```bash
source "skills/read-only-gh-pr-review/scripts/activate-gh-readonly.sh"
gh-readonly-status
gh auth status
```

3. Ask the agent to review a PR, or inspect the PR manually with `gh` in that protected session.
4. Review findings in chat only. Do not post comments or reviews back to GitHub.

## Example Prompts

```text
Use read-only-gh-pr-review to review PR #123 and report only must-fix and should-fix issues.
```

```text
Review the open backend PR on this branch with read-only-gh-pr-review. Focus on correctness, auth, database safety, and missing tests.
```

## Typical Review Flow

```bash
gh pr view 123 --json title,body,headRefName,baseRefName
gh pr diff 123 --name-only
gh pr checks 123
```

The skill can then correlate that data with local file inspection and produce a structured review.

## Notes

- `SKILL.md` contains the full review workflow and response format.
- `references/review-checklist.md` contains the review checklist used for risk-first auditing.
- `references/github-cli-map.md` maps common review tasks to GitHub CLI commands.
