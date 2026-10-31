# Netizen Dev — Codex working instructions

## Purpose
This repository is the user's mobile-first development workspace. Work should be practical from iPad/iPhone, using GitHub and cloud-based coding. The user decides scope and approves consequential actions.

## Stack
- Python 3.12 and Node.js 22 are available in the Codex environment.
- Existing proof of concept: `hello.py` and `dashboard.py`; dashboard serves HTTP on port 8000 with `/api/status`.
- Prefer standard-library, lightweight, reproducible solutions unless a dependency is justified.

## Workflow
1. Inspect the repository and relevant files before editing.
2. Explain the proposed change briefly, then implement the requested task.
3. Run appropriate checks and report actual results; never claim an unperformed test.
4. Preserve existing functionality and avoid unrelated edits.
5. State changed file paths, commands used, limitations, and any required user action.
6. Do not expose secrets or credentials. Use environment secrets for tokens.
7. Ask before deleting files, deploying publicly, incurring costs, or changing permissions.
8. Prefer small commits with descriptive messages; do not claim a commit unless it exists.

## Communication
- Communicate in Turkish unless asked otherwise.
- When providing a URL, always show the complete plain-text URL first and then an optional clickable link. Explain what destination it opens.
- Give concise, sequential iPad-friendly instructions.
- Distinguish confirmed results from assumptions.
- Treat security and factual correctness as priorities.

## Web previews
- Localhost inside a cloud environment is not automatically reachable from the user's iPad.
- Test local HTTP endpoints first; if a public preview is unavailable, explain that explicitly and propose an approved deployment or port-forwarding option.
- Do not enable broad public network access unless necessary.

## Current project
The first deliverable is a mobile-friendly Netizen Dev dashboard. Keep it functional and minimal. Future features should be user-directed.

## Continuity between Codex and ChatGPT
- After each completed development task, update `PROGRESS.md` with date, goal, files changed, tests actually run, outcome, unresolved issues, and next suggested step.
- Commit `PROGRESS.md` together with the implementation when possible, so other GitHub-connected sessions can inspect progress.
- Do not include credentials, personal data, or unverified success claims in progress notes.
