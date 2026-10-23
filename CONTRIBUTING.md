# Contributing

Suggestions, corrections and new one-liners are welcome. Open an issue or a pull request.

## Content guidelines

- One task per entry: a `###` heading, a one-line explanation, and a `powershell` code block.
- Replace real infrastructure values with the placeholders listed in the
  [README](README.md#conventions) (`example.com`, `dc01.example.com`, `GroupName`, ...).
  Never include credentials, real domain names, tenant identifiers or other production data.
- Mark commands that change Active Directory with ⚠️ and explain their impact; add a warning for
  irreversible or high-impact changes.
- Document required modules, permissions and platform limitations.
- Support Windows PowerShell 5.1 and PowerShell 7 where the underlying module allows it.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/), for example:

- `feat(ad-users): add time-limited membership example`
- `fix(ad-security): correct inactive account filter`
- `docs: clarify module prerequisites`
