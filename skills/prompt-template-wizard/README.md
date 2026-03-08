# prompt-template-wizard

Interactive skill for turning rough feature requests and bug reports into complete, paste-ready prompts for a coding agent.

## What It Is

This skill collects the missing context needed to produce a high-quality implementation prompt. It keeps scope bounded, makes testing explicit, and refuses to finalize until the request is specific enough to execute.

It is best used when a request is still vague, missing acceptance criteria, or missing codebase pointers.

## What It Produces

- A final prompt template you can paste into a coding session
- A filled `TemplateSpec` with the resolved requirements
- A consistency checklist to confirm the request is actionable

## When To Use It

- A feature request is still underspecified
- A bug report is missing repro details or expected behavior
- You want clearer scope, acceptance criteria, and test expectations before implementation
- You are handing work off to another agent and want a tighter prompt

## How To Use It

1. Make the skill available under `skills/prompt-template-wizard`.
2. Ask the agent to use the skill on your rough request.
3. Answer the follow-up questions until all required fields are resolved.
4. Use the generated prompt template as the implementation handoff.

## Example Prompts

```text
Use prompt-template-wizard to turn this into a complete implementation prompt:
Add a bulk archive action to the notifications page.
```

```text
Use prompt-template-wizard for a bug fix:
Users sometimes get logged out during checkout after refreshing the page.
```

## Notes

- `SKILL.md` contains the full operating rules and output schema.
- This skill is interactive by design. If information is missing, it should keep asking until the prompt is complete.
