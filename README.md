# Active Directory PowerShell One-Liners

[![PowerShell 5.1 | 7](https://img.shields.io/badge/PowerShell-5.1%20%7C%207-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Module: ActiveDirectory](https://img.shields.io/badge/module-ActiveDirectory-0078D4)](https://learn.microsoft.com/powershell/module/activedirectory/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Copy-paste ready PowerShell one-liners for everyday Active Directory administration:
health and replication checks, FSMO roles, security audits, and user and group management.

## Contents

| Topic | What you will find |
| --- | --- |
| [Health and replication](PSOneLiners/AD-Health.md) | Domain controllers, replication partners and replication failures |
| [Repadmin](PSOneLiners/repadmin.md) | Step-by-step replication troubleshooting with `repadmin.exe` |
| [FSMO roles](PSOneLiners/AD-FSMO.md) | Find and transfer operations master roles |
| [Security](PSOneLiners/AD-Security.md) | Inactive computers, risky account flags, privileged groups, SPNs |
| [Users and groups](PSOneLiners/AD-Users.md) | Counts, group membership, temporary membership, passwords, lockouts, mail attributes |
| [Optional features](PSOneLiners/AD-Features.md) | Privileged Access Management feature |

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7 on Windows.
- The **ActiveDirectory** module from RSAT:

  ```powershell
  # Windows 10 / 11
  Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

  # Windows Server
  Install-WindowsFeature -Name RSAT-AD-PowerShell
  ```

- Read access to the directory is enough for queries. Commands that change Active Directory
  need the matching administrative rights.
- `repadmin.exe` is included with the AD DS role and the RSAT AD DS tools.

## Conventions

- **Placeholders**: replace them with values from your environment before running a command.

  | Placeholder | Meaning |
  | --- | --- |
  | `example.com`, `DC=example,DC=com` | Your domain (DNS name / distinguished name) |
  | `dc01.example.com` | A domain controller |
  | `GroupName`, `AccountName`, `UserName` | A group, user or computer account |
  | `SourceUser`, `TargetUser` | Accounts used when copying group memberships |
  | `New-Host`, `RoleName` | Target domain controller and FSMO role name |

- ⚠️ marks commands that **change** Active Directory. Everything else is read-only.
  Try changes in a lab or with `-WhatIf` (where supported) before running them in production.

## Contributing

Suggestions and corrections are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Released under the [MIT License](LICENSE).
