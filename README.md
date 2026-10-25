# Windows and Active Directory PowerShell One-Liners

[![PowerShell 5.1 | 7](https://img.shields.io/badge/PowerShell-5.1%20%7C%207-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Module: ActiveDirectory](https://img.shields.io/badge/module-ActiveDirectory-0078D4)](https://learn.microsoft.com/powershell/module/activedirectory/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Copy-paste ready PowerShell one-liners for everyday Windows and Active Directory administration:
event log queries, Windows Firewall rules, health and replication checks, FSMO roles, security
audits, and user and group management.

## Contents

| Topic | What you will find |
| --- | --- |
| [Windows event logs](PSOneLiners/Windows-Events.md) | Logons, restarts, installed software and updates, security-relevant events, log maintenance |
| [Windows Firewall](PSOneLiners/Windows-Firewall.md) | Profile status, rules for a port or an application, adding, changing and removing rules, firewall logging |
| [Active Directory events](PSOneLiners/AD-Events.md) | Lockout sources, failed authentication, group and account changes, RC4 Kerberos tickets |
| [Health and replication](PSOneLiners/AD-Health.md) | Domain controllers, replication, dcdiag, time sync, SYSVOL, functional levels, schema |
| [Repadmin](PSOneLiners/repadmin.md) | Step-by-step replication troubleshooting with `repadmin.exe` |
| [FSMO roles](PSOneLiners/AD-FSMO.md) | Find and transfer operations master roles |
| [Security](PSOneLiners/AD-Security.md) | Risky account flags, privileged groups, delegation, krbtgt, password policies, trusts, LAPS, recent changes |
| [Users and groups](PSOneLiners/AD-Users.md) | Inactive and new accounts, real last logon, group membership, temporary membership, passwords, lockouts, mail attributes |
| [Optional features](PSOneLiners/AD-Features.md) | Privileged Access Management, Recycle Bin, restoring deleted objects |

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7 on Windows.
- The **ActiveDirectory** module from RSAT for the Active Directory pages:

  ```powershell
  # Windows 10 / 11
  Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

  # Windows Server
  Install-WindowsFeature -Name RSAT-AD-PowerShell
  ```

- Read access to the directory is enough for queries. Commands that change Active Directory
  need the matching administrative rights.
- `repadmin.exe`, `dcdiag.exe` and `dfsrmig.exe` are included with the AD DS role and the RSAT AD DS tools.
- `Get-GPO` needs the **GroupPolicy** module (RSAT Group Policy Management Tools,
  `Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0` on Windows 10 / 11).
- Event log queries: reading the Security log requires an elevated session or membership in
  *Event Log Readers*; most Security events are only written when the matching audit policy is
  enabled; remote queries need the *Remote Event Log Management* firewall rule. The event log pages
  need no extra module.
- Windows Firewall: the built-in **NetSecurity** module (Windows 8 / Server 2012 and newer). Changing
  rules requires an elevated session; rules in a GPO also need edit rights on the GPO.

## Conventions

- **Placeholders**: replace them with values from your environment before running a command.

  | Placeholder | Meaning |
  | --- | --- |
  | `example.com`, `DC=example,DC=com` | Your domain (DNS name / distinguished name) |
  | `dc01.example.com` | A domain controller |
  | `server01.example.com` | Any Windows server or client |
  | `GroupName`, `AccountName`, `UserName` | A group, user or computer account |
  | `SourceUser`, `TargetUser` | Accounts used when copying group memberships |
  | `New-Host`, `RoleName` | Target domain controller and FSMO role name |
  | `Allow TCP 8080`, `C:\Program Files\App\app.exe` | Firewall rule name and application path |
  | `192.0.2.0/24`, `198.51.100.10` | IP addresses reserved for documentation (RFC 5737) |
  | `Firewall Policy` | A Group Policy Object |

- ⚠️ marks commands that **change** Active Directory or the system. Everything else is read-only.
  Try changes in a lab or with `-WhatIf` (where supported) before running them in production.

## Contributing

Suggestions and corrections are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Released under the [MIT License](LICENSE).
