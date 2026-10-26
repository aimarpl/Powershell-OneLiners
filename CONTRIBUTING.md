# Contributing

Suggestions, corrections and new one-liners are welcome. Open an issue or a pull request.

## Content guidelines

- One task per entry: a `###` heading, a one-line explanation, and a `powershell` code block.
- Replace real infrastructure values with the placeholders listed in the
  [README](README.md#conventions) (`example.com`, `dc01.example.com`, `GroupName`, ...).
  Never include credentials, real domain names, tenant identifiers or other production data.
- Mark commands that change Active Directory or the system with ⚠️ and explain their impact; add a
  warning for irreversible or high-impact changes.
- Document required modules, permissions and platform limitations.
- Support Windows PowerShell 5.1 and PowerShell 7 where the underlying module allows it.
- Event log queries: use `-FilterHashtable` or `-FilterXPath` so the filtering happens in the event log
  service, and verify event field positions (`$_.Properties[n]`) against the event template.
- Use full cmdlet and parameter names. `Format-List`, not `fl`; `Where-Object`, not `Where`.
- Type the code by hand or paste from a terminal, never from a document or chat
  client. Those replace `-` with `–` and `'` with `’`, which looks right in a
  browser and fails the moment someone pastes it into a console.

## Validation

Run before opening a pull request:

```bash
# Smart quotes and dashes that break on paste
python3 tools/check-code-characters.py .

# Markdown formatting
npx --yes markdownlint-cli2 "**/*.md"
```

```powershell
# PSScriptAnalyzer across every PowerShell block in the Markdown
./tools/Invoke-MarkdownScriptAnalyzer.ps1
```

The examples live inside fenced code blocks rather than `.ps1` files, so
`Invoke-MarkdownScriptAnalyzer.ps1` extracts each block and analyzes it,
reporting findings against the Markdown file and line. Pointing PSScriptAnalyzer
at `*.ps1` here finds nothing and passes, which is why that is not what CI does.

All three checks run in CI on every push and pull request, with the analyzer
executed under both Windows PowerShell 5.1 and PowerShell 7.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/), for example:

- `feat(ad-users): add time-limited membership example`
- `fix(ad-security): correct inactive account filter`
- `docs: clarify module prerequisites`
