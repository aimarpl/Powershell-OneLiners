# Contributing

## Content guidelines

- Use full cmdlet and parameter names in published examples.
- Use `powershell` fenced code blocks.
- Replace real infrastructure values with obvious placeholders.
- Document required modules, permissions, and runtime limitations.
- Add a warning and a safe preview for destructive or high-impact commands.
- Support Windows PowerShell 5.1 and PowerShell 7 where the underlying module permits it.

## Commits and pull requests

Use Conventional Commits, such as:

- `feat(ad-users): add time-limited membership example`
- `fix(ad-security): correct audit policy command`
- `docs: clarify module prerequisites`

Small corrections may be committed directly to `main`. Use a focused branch and pull request for larger additions or structural changes. Pull requests are squash-merged after approval.

## Validation

Before publishing:

1. Run Markdown linting.
2. Run PSScriptAnalyzer when script files are changed.
3. Review examples for compatibility with Windows PowerShell 5.1 and PowerShell 7.
4. Confirm that examples contain no production-specific or sensitive values.
