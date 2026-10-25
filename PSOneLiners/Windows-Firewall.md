# Windows Firewall

[← Back to index](../README.md)

One-liners for Windows Defender Firewall with the built-in **NetSecurity** module: profile status,
finding rules for a port or an application, adding, changing and removing rules, logging and
troubleshooting. Commands are read-only unless marked ⚠️.

- Changing the firewall requires an **elevated** PowerShell session.
- To manage another computer, add `-CimSession server01.example.com` to any NetSecurity cmdlet
  (`Get-NetFirewallRule`, `New-NetFirewallRule`, ...). This uses WinRM.
- `Get-NetFirewallRule` without `-PolicyStore` returns only the **local** rules. Add
  `-PolicyStore ActiveStore` to see the policy the firewall actually enforces, including rules from
  Group Policy. Rules that come from Group Policy cannot be changed or removed locally.
- `-DisplayName` and `-DisplayGroup` are localized and a display name does not have to be unique.
  The rule name (`-Name`) and the rule group ID (`-Group '@FirewallAPI.dll,-28752'`) are the same on
  every language version.
- `-Profile Any` (the default for new rules) applies a rule to the Domain, Private and Public profiles.
  Which profile is in effect depends on the network, see
  [Network profile of each connection](#network-profile-of-each-connection).

- Status
  - [Firewall state and default actions per profile](#firewall-state-and-default-actions-per-profile)
  - [Network profile of each connection](#network-profile-of-each-connection)
- Find rules
  - [Rules that open a port](#rules-that-open-a-port)
  - [Rules for an application](#rules-for-an-application)
  - [Enabled inbound allow rules](#enabled-inbound-allow-rules)
  - [Rules without a rule group](#rules-without-a-rule-group)
  - [Ports, addresses and program of a rule](#ports-addresses-and-program-of-a-rule)
  - [Rule groups and their IDs](#rule-groups-and-their-ids)
  - [Rules in a built-in rule group](#rules-in-a-built-in-rule-group)
  - [Rules from Group Policy](#rules-from-group-policy)
- Add rules
  - ⚠️ [Allow an inbound port on all profiles](#allow-an-inbound-port-on-all-profiles)
  - ⚠️ [Allow an inbound port on the domain profile only](#allow-an-inbound-port-on-the-domain-profile-only)
  - ⚠️ [Allow several ports or a port range](#allow-several-ports-or-a-port-range)
  - ⚠️ [Allow a port only from specific addresses](#allow-a-port-only-from-specific-addresses)
  - ⚠️ [Allow an application](#allow-an-application)
  - ⚠️ [Block outbound traffic of an application](#block-outbound-traffic-of-an-application)
  - ⚠️ [Allow ping](#allow-ping)
  - ⚠️ [Add a rule to a Group Policy Object](#add-a-rule-to-a-group-policy-object)
- Change and remove rules
  - ⚠️ [Enable or disable a rule](#enable-or-disable-a-rule)
  - ⚠️ [Enable a built-in rule group](#enable-a-built-in-rule-group)
  - ⚠️ [Change the port or profile of a rule](#change-the-port-or-profile-of-a-rule)
  - ⚠️ [Remove a rule](#remove-a-rule)
  - ⚠️ [Remove all local rules for a port](#remove-all-local-rules-for-a-port)
  - ⚠️ [Turn on the firewall for all profiles](#turn-on-the-firewall-for-all-profiles)
- Logging and troubleshooting
  - [Process listening on a port](#process-listening-on-a-port)
  - [Test a port from another computer](#test-a-port-from-another-computer)
  - [Firewall rule changes in the last 7 days](#firewall-rule-changes-in-the-last-7-days)
  - ⚠️ [Log dropped packets](#log-dropped-packets)
  - [Last dropped packets](#last-dropped-packets)
  - ⚠️ [Export the firewall policy](#export-the-firewall-policy)
  - ⚠️ [Import the firewall policy](#import-the-firewall-policy)

## Status

### Firewall state and default actions per profile

The effective settings, including Group Policy. In the local store `NotConfigured` means the Windows
default: inbound connections are blocked, outbound connections are allowed. When
`AllowLocalFirewallRules` is `False`, Group Policy ignores all local rules.

```powershell
Get-NetFirewallProfile -PolicyStore ActiveStore | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, AllowLocalFirewallRules, LogBlocked, LogFileName
```

### Network profile of each connection

`DomainAuthenticated` uses the Domain profile, `Private` and `Public` the matching profile. A domain
member that shows `Public` or `Private` could not reach a domain controller when the network was
identified.

```powershell
Get-NetConnectionProfile | Select-Object InterfaceAlias, Name, NetworkCategory, IPv4Connectivity
```

## Find rules

### Rules that open a port

All rules, local and from Group Policy, whose local port list contains the port, including port ranges
such as `5000-5100`. Rules for all ports (`Any`), for example most application rules, are not listed;
see [Rules for an application](#rules-for-an-application).

```powershell
$Port = 3389; Get-NetFirewallPortFilter -PolicyStore ActiveStore | Where-Object { @($_.LocalPort | Where-Object { $_ -eq "$Port" -or ($_ -match '^(\d+)-(\d+)$' -and $Port -ge [int]$Matches[1] -and $Port -le [int]$Matches[2]) }).Count } | Get-NetFirewallRule | Select-Object DisplayName, Enabled, Direction, Action, Profile, @{n='Protocol';e={($_ | Get-NetFirewallPortFilter).Protocol}}, PolicyStoreSourceType
```

### Rules for an application

Rules bound to a program, matched by file name. Program paths may contain environment variables such
as `%ProgramFiles%`, so match the end of the path.

```powershell
Get-NetFirewallApplicationFilter -PolicyStore ActiveStore | Where-Object Program -like '*\app.exe' | Get-NetFirewallRule | Select-Object DisplayName, Enabled, Direction, Action, Profile
```

### Enabled inbound allow rules

Everything the firewall currently lets in, sorted by rule group.

```powershell
Get-NetFirewallRule -PolicyStore ActiveStore -Direction Inbound -Enabled True -Action Allow | Sort-Object DisplayGroup, DisplayName | Select-Object DisplayName, DisplayGroup, Profile
```

### Rules without a rule group

Built-in rules belong to a rule group. Rules without one were usually added by an administrator, a
script or an installer.

```powershell
Get-NetFirewallRule | Where-Object { -not $_.Group } | Select-Object DisplayName, Enabled, Direction, Action, Profile
```

### Ports, addresses and program of a rule

The `Get-NetFirewallRule` output does not include ports, addresses or programs; they are stored in
separate filter objects.

```powershell
Get-NetFirewallRule -DisplayName 'Allow TCP 8080' | ForEach-Object { $p = $_ | Get-NetFirewallPortFilter; [pscustomobject]@{ Name = $_.DisplayName; Enabled = $_.Enabled; Direction = $_.Direction; Action = $_.Action; Profile = $_.Profile; Protocol = $p.Protocol; LocalPort = $p.LocalPort -join ','; RemoteAddress = ($_ | Get-NetFirewallAddressFilter).RemoteAddress -join ','; Program = ($_ | Get-NetFirewallApplicationFilter).Program } }
```

### Rule groups and their IDs

The group ID in the `Group` column does not depend on the language of Windows.

```powershell
Get-NetFirewallRule | Where-Object Group | Group-Object Group | Select-Object Count, @{n='DisplayGroup';e={$_.Group[0].DisplayGroup}}, @{n='Group';e={$_.Name}} | Sort-Object DisplayGroup
```

### Rules in a built-in rule group

Common group IDs:

| Rule group | Group ID |
| --- | --- |
| Remote Desktop | `@FirewallAPI.dll,-28752` |
| File and Printer Sharing | `@FirewallAPI.dll,-28502` |
| Remote Event Log Management | `@FirewallAPI.dll,-29252` |
| Remote Service Management | `@FirewallAPI.dll,-29502` |
| Windows Remote Management | `@FirewallAPI.dll,-30267` |

```powershell
Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Select-Object Name, DisplayName, Enabled, Profile
```

### Rules from Group Policy

Rules delivered by Group Policy. Empty output means no firewall rules come from Group Policy.

```powershell
Get-NetFirewallRule -PolicyStore ActiveStore | Where-Object PolicyStoreSourceType -eq 'GroupPolicy' | Select-Object DisplayName, Enabled, Direction, Action, Profile, PolicyStoreSource
```

## Add rules

### Allow an inbound port on all profiles

⚠️ **Changes the system.**

```powershell
New-NetFirewallRule -DisplayName 'Allow TCP 8080' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Any
```

### Allow an inbound port on the domain profile only

⚠️ **Changes the system.**

The port is open only while the computer is connected to the domain network. Use
`-Profile Domain, Private` for several profiles.

```powershell
New-NetFirewallRule -DisplayName 'Allow TCP 8080' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Domain
```

### Allow several ports or a port range

⚠️ **Changes the system.**

`-LocalPort` accepts a list of ports and ranges. One rule covers one protocol; create a second rule
for TCP.

```powershell
New-NetFirewallRule -DisplayName 'Allow UDP 5000-5100' -Direction Inbound -Protocol UDP -LocalPort '5000-5100', 5200 -Action Allow
```

### Allow a port only from specific addresses

⚠️ **Changes the system.**

`-RemoteAddress` accepts addresses, subnets, ranges (`192.0.2.10-192.0.2.20`) and keywords such as
`LocalSubnet`.

```powershell
New-NetFirewallRule -DisplayName 'Allow TCP 1433 from admin network' -Direction Inbound -Protocol TCP -LocalPort 1433 -RemoteAddress 192.0.2.0/24, 198.51.100.10 -Action Allow -Profile Domain
```

### Allow an application

⚠️ **Changes the system.**

Allows inbound connections to all ports the program listens on.

```powershell
New-NetFirewallRule -DisplayName 'Allow App' -Direction Inbound -Program 'C:\Program Files\App\app.exe' -Action Allow -Profile Domain, Private
```

### Block outbound traffic of an application

⚠️ **Changes the system.**

A block rule takes precedence over allow rules.

```powershell
New-NetFirewallRule -DisplayName 'Block App outbound' -Direction Outbound -Program 'C:\Program Files\App\app.exe' -Action Block
```

### Allow ping

⚠️ **Changes the system.**

Enables the built-in ICMPv4 echo request rule (*File and Printer Sharing (Echo Request - ICMPv4-In)*).
The IPv6 rule is `FPS-ICMP6-ERQ-In`.

```powershell
Enable-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In'
```

### Add a rule to a Group Policy Object

⚠️ **Changes Group Policy.**

Writes the rule into an existing GPO (`domain\GPO name`); it applies to every computer in the scope
of the GPO at the next policy refresh. Needs edit rights on the GPO and the GroupPolicy module tools.

```powershell
New-NetFirewallRule -PolicyStore 'example.com\Firewall Policy' -DisplayName 'Allow TCP 8080' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Domain
```

## Change and remove rules

### Enable or disable a rule

⚠️ **Changes the system.**

Disabling keeps the rule so it can be enabled again later.

```powershell
Disable-NetFirewallRule -DisplayName 'Allow TCP 8080'
```

```powershell
Enable-NetFirewallRule -DisplayName 'Allow TCP 8080'
```

### Enable a built-in rule group

⚠️ **Changes the system.**

Enables all rules of the Remote Desktop group. Other group IDs are listed in
[Rules in a built-in rule group](#rules-in-a-built-in-rule-group). This only opens the firewall;
Remote Desktop itself must be enabled separately.

```powershell
Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'
```

### Change the port or profile of a rule

⚠️ **Changes the system.**

```powershell
Set-NetFirewallRule -DisplayName 'Allow TCP 8080' -LocalPort 8081 -Profile Domain
```

### Remove a rule

⚠️ **Changes the system.**

Removes **every** local rule with this display name. List them first with
`Get-NetFirewallRule -DisplayName 'Allow TCP 8080'`. Disable built-in rules instead of removing them.

```powershell
Remove-NetFirewallRule -DisplayName 'Allow TCP 8080'
```

### Remove all local rules for a port

⚠️ **Changes the system.**

Removes local rules whose port list contains exactly this port (no ranges). The command runs with
`-WhatIf` and only lists the rules; remove `-WhatIf` to delete them.

```powershell
Get-NetFirewallPortFilter | Where-Object LocalPort -contains '8080' | Get-NetFirewallRule | Remove-NetFirewallRule -WhatIf
```

### Turn on the firewall for all profiles

⚠️ **Changes the system.**

Group Policy settings take precedence over local settings.

```powershell
Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True
```

## Logging and troubleshooting

### Process listening on a port

Shows whether anything listens on the port at all; a closed port is not always the firewall. Services
hosted in `svchost` show `svchost` as the process. Use `Get-NetUDPEndpoint -LocalPort` for UDP.

```powershell
Get-NetTCPConnection -LocalPort 3389 -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess, @{n='Process';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
```

### Test a port from another computer

Run on the client. `TcpTestSucceeded` is `False` when the port is blocked or nothing is listening.

```powershell
Test-NetConnection -ComputerName server01.example.com -Port 3389 | Select-Object ComputerName, RemoteAddress, RemotePort, TcpTestSucceeded
```

### Firewall rule changes in the last 7 days

Rules added, modified and deleted, with the account (SID) and program that made the change. Windows
Server 2022 and older log events 2004, 2005 and 2006; newer Windows 10 and 11 builds log 2071, 2097
(added), 2099 (modified) and 2052 (deleted). Windows updates also add and modify rules.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Firewall With Advanced Security/Firewall'; Id=2004,2005,2006,2052,2071,2097,2099; StartTime=(Get-Date).AddDays(-7)} | ForEach-Object { $d = @{}; ([xml]$_.ToXml()).Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }; [pscustomobject]@{ TimeCreated = $_.TimeCreated; Change = @{2004='Added'; 2071='Added'; 2097='Added'; 2005='Modified'; 2099='Modified'; 2006='Deleted'; 2052='Deleted'}[$_.Id]; Rule = $d.RuleName; User = $d.ModifyingUser; Program = $d.ModifyingApplication } }
```

### Log dropped packets

⚠️ **Changes the system.**

Writes dropped packets to `%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log` (16 MB). Group Policy
logging settings take precedence. Set `-LogBlocked False` when you are done.

```powershell
Set-NetFirewallProfile -Profile Domain, Private, Public -LogBlocked True -LogMaxSizeKilobytes 16384
```

### Last dropped packets

Reads the end of the firewall log written by [Log dropped packets](#log-dropped-packets). Requires
elevation.

```powershell
Get-Content "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log" -Tail 2000 | Where-Object { $_ -match ' DROP ' } | ConvertFrom-Csv -Delimiter ' ' -Header Date, Time, Action, Protocol, SrcIP, DstIP, SrcPort, DstPort | Select-Object -Last 20
```

### Export the firewall policy

⚠️ **Writes a file.**

Exports the complete local firewall configuration (profiles and rules); the target folder must exist.
Requires elevation.

```powershell
netsh advfirewall export "C:\Backup\$env:COMPUTERNAME-firewall-$(Get-Date -Format yyyyMMdd).wfw"
```

### Import the firewall policy

⚠️ **Changes the system.**

> [!CAUTION]
> The import **replaces** the complete local firewall configuration, including all local rules.
> A wrong file can block your remote session. Export the current policy first.

```powershell
netsh advfirewall import "C:\Backup\server01-firewall-20250101.wfw"
```

---

See also: [Windows event logs](Windows-Events.md) for logons, restarts and other security-relevant
events.
