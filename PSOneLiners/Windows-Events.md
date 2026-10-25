# Windows event logs

[← Back to index](../README.md)

Log management one-liners for Windows servers and clients: logons, restarts, installed software and
updates, security-relevant events and log maintenance. Commands are read-only unless marked ⚠️.

- Run PowerShell **elevated** (or as a member of *Event Log Readers*) to read the Security log.
- To query another computer, add `-ComputerName server01.example.com` to `Get-WinEvent`. This needs
  the *Remote Event Log Management* firewall rule on the target.
- Change the time window with `AddDays(-1)` / `AddDays(-7)`, or in XPath filters with the value in
  milliseconds (`86400000` = 24 hours, `604800000` = 7 days).
- `Get-WinEvent` reports *No events were found that match the specified selection criteria* when
  nothing matches; that is not a failure.
- Security log events are only written if the matching audit policy is enabled, see
  [Audit policy in effect](#audit-policy-in-effect).

- Logons
  - [Interactive and RDP logons in the last 24 hours](#interactive-and-rdp-logons-in-the-last-24-hours)
  - [Failed logons in the last 24 hours by account and source](#failed-logons-in-the-last-24-hours-by-account-and-source)
  - [Administrator logons in the last 24 hours](#administrator-logons-in-the-last-24-hours)
  - [Logons with explicit credentials in the last 24 hours](#logons-with-explicit-credentials-in-the-last-24-hours)
  - [Remote Desktop sessions in the last 7 days](#remote-desktop-sessions-in-the-last-7-days)
- Restarts and errors
  - [Shutdown and restart events in the last 7 days](#shutdown-and-restart-events-in-the-last-7-days)
  - [Who restarted or shut down the computer](#who-restarted-or-shut-down-the-computer)
  - [Last boot time and uptime](#last-boot-time-and-uptime)
  - [Top errors and critical events in the last 24 hours](#top-errors-and-critical-events-in-the-last-24-hours)
- Software and updates
  - [Software installed in the last 7 days](#software-installed-in-the-last-7-days)
  - [MSI installs and removals in the last 7 days](#msi-installs-and-removals-in-the-last-7-days)
  - [Windows updates installed in the last 30 days](#windows-updates-installed-in-the-last-30-days)
  - [Failed Windows updates in the last 30 days](#failed-windows-updates-in-the-last-30-days)
  - [Hotfixes installed in the last 30 days](#hotfixes-installed-in-the-last-30-days)
- Security-relevant events
  - [Services installed in the last 7 days](#services-installed-in-the-last-7-days)
  - [Scheduled tasks created in the last 7 days](#scheduled-tasks-created-in-the-last-7-days)
  - [Local group membership changes in the last 7 days](#local-group-membership-changes-in-the-last-7-days)
  - [Local user accounts created or deleted in the last 7 days](#local-user-accounts-created-or-deleted-in-the-last-7-days)
  - [Event logs cleared](#event-logs-cleared)
  - [Suspicious PowerShell script blocks in the last 7 days](#suspicious-powershell-script-blocks-in-the-last-7-days)
  - [Microsoft Defender detections in the last 30 days](#microsoft-defender-detections-in-the-last-30-days)
- Log maintenance
  - [Size and retention of the main logs](#size-and-retention-of-the-main-logs)
  - [Oldest event in each log](#oldest-event-in-each-log)
  - [Largest event logs](#largest-event-logs)
  - [Audit policy in effect](#audit-policy-in-effect)
  - ⚠️ [Export a log to an .evtx file](#export-a-log-to-an-evtx-file)
  - [Read events from an exported .evtx file](#read-events-from-an-exported-evtx-file)
  - ⚠️ [Increase the maximum size of the Security log](#increase-the-maximum-size-of-the-security-log)

## Logons

### Interactive and RDP logons in the last 24 hours

Successful logons (event 4624) of type 2 (console), 10 (Remote Desktop) and 11 (cached credentials).
Window Manager and Font Driver Host system logons are filtered out. With UAC an administrator logon is
logged twice (filtered and elevated token). Add `or Data[@Name='LogonType']='3'` for network logons.

```powershell
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4624 and TimeCreated[timediff(@SystemTime) <= 86400000]] and EventData[Data[@Name='LogonType']='2' or Data[@Name='LogonType']='10' or Data[@Name='LogonType']='11']]" | Where-Object { $_.Properties[4].Value -notmatch '^S-1-5-(90|96)-' } | Select-Object TimeCreated, @{n='User';e={'{0}\{1}' -f $_.Properties[6].Value, $_.Properties[5].Value}}, @{n='LogonType';e={$_.Properties[8].Value}}, @{n='SourceIP';e={$_.Properties[18].Value}}
```

### Failed logons in the last 24 hours by account and source

Event 4625 grouped by account and source IP address. Many failures for many accounts from one source
suggest password spraying; many failures for one account suggest a stale saved password or brute force.
When the event has no domain name, the account is shown without a leading backslash.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddDays(-1)} | Group-Object {if ($_.Properties[6].Value) {'{0}\{1}' -f $_.Properties[6].Value, $_.Properties[5].Value} else {$_.Properties[5].Value}}, {$_.Properties[19].Value} | Sort-Object Count -Descending | Select-Object Count, Name
```

### Administrator logons in the last 24 hours

Event 4672 (special privileges assigned to a new logon) is written for every logon with administrative
privileges. SYSTEM, LOCAL SERVICE, NETWORK SERVICE, Window Manager / Font Driver Host and computer
accounts are filtered out.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4672; StartTime=(Get-Date).AddDays(-1)} | Where-Object { "$($_.Properties[0].Value)" -notmatch '^S-1-5-(18|19|20)$|^S-1-5-(90|96)-' -and $_.Properties[1].Value -notlike '*$' } | Group-Object {'{0}\{1}' -f $_.Properties[2].Value, $_.Properties[1].Value} | Sort-Object Count -Descending | Select-Object Count, Name
```

### Logons with explicit credentials in the last 24 hours

Event 4648 is written when a process logs on with different credentials, for example `runas`, mapped
drives with another account or remote administration tools, so it is useful for spotting lateral
movement. The account is shown without a leading backslash when the event has no target domain.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4648; StartTime=(Get-Date).AddDays(-1)} | Where-Object { $_.Properties[1].Value -notlike '*$' } | Select-Object TimeCreated, @{n='User';e={$_.Properties[1].Value}}, @{n='UsedAccount';e={if ($_.Properties[6].Value) {'{0}\{1}' -f $_.Properties[6].Value, $_.Properties[5].Value} else {$_.Properties[5].Value}}}, @{n='TargetServer';e={$_.Properties[8].Value}}, @{n='Process';e={$_.Properties[11].Value}}
```

### Remote Desktop sessions in the last 7 days

Session logon, logoff, disconnect and reconnect events from the Remote Desktop session manager. No
elevation required. Console sessions show `LOCAL` (localized) as the source.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,23,24,25; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Event';e={@{21='Logon';23='Logoff';24='Disconnected';25='Reconnected'}[$_.Id]}}, @{n='User';e={$_.Properties[0].Value}}, @{n='Source';e={$_.Properties[2].Value}}
```

## Restarts and errors

### Shutdown and restart events in the last 7 days

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074,6005,6006,6008,41; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, Id, @{n='Event';e={@{1074='Shutdown/restart initiated';6005='Event log started (boot)';6006='Clean shutdown';6008='Unexpected shutdown';41='Rebooted without clean shutdown'}[$_.Id]}}
```

### Who restarted or shut down the computer

Event 1074 records the account, the action, the reason and the process that initiated a shutdown or
restart (last 7 days).

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='User';e={$_.Properties[6].Value}}, @{n='Action';e={$_.Properties[4].Value}}, @{n='Reason';e={$_.Properties[2].Value}}, @{n='Comment';e={$_.Properties[5].Value}}, @{n='Process';e={$_.Properties[0].Value}}
```

### Last boot time and uptime

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object CSName, LastBootUpTime, @{n='Uptime';e={(Get-Date) - $_.LastBootUpTime}}
```

### Top errors and critical events in the last 24 hours

The 20 most frequent error and critical events in the System and Application logs.

```powershell
Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddDays(-1)} | Group-Object LogName, ProviderName, Id | Sort-Object Count -Descending | Select-Object -First 20 Count, Name
```

## Software and updates

> [!NOTE]
> Avoid `Get-WmiObject Win32_Product` / `Get-CimInstance Win32_Product` for software inventory: the
> query runs a consistency check of every MSI package and can trigger repairs. Use the registry and the
> event log as shown below.

### Software installed in the last 7 days

Reads the Uninstall registry keys (64-bit, 32-bit and the current user), so non-MSI installers are
included. Keys that do not exist on the computer are ignored, and entries without a valid `InstallDate`
are skipped.

```powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.InstallDate -match '^\d{8}$' -and $_.InstallDate -ge (Get-Date).AddDays(-7).ToString('yyyyMMdd') } | Sort-Object InstallDate -Descending | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
```

### MSI installs and removals in the last 7 days

Windows Installer events 1033 (installed) and 1034 (removed), with product, version and vendor.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; Id=1033,1034; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Action';e={@{1033='Installed';1034='Removed'}[$_.Id]}}, @{n='Product';e={$_.Properties[0].Value}}, @{n='Version';e={$_.Properties[1].Value}}, @{n='Vendor';e={$_.Properties[4].Value}}
```

### Windows updates installed in the last 30 days

Includes cumulative updates, Defender intelligence updates and Store app updates.

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=19; StartTime=(Get-Date).AddDays(-30)} | Select-Object TimeCreated, @{n='Update';e={$_.Properties[0].Value}}
```

### Failed Windows updates in the last 30 days

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=20; StartTime=(Get-Date).AddDays(-30)} | Select-Object TimeCreated, @{n='Update';e={$_.Properties[1].Value}}, @{n='ErrorCode';e={'0x{0:X8}' -f $_.Properties[0].Value}}
```

### Hotfixes installed in the last 30 days

Operating system updates (KBs) only. `Get-HotFix` also accepts `-ComputerName`.

```powershell
Get-HotFix | Where-Object InstalledOn -gt (Get-Date).AddDays(-30) | Sort-Object InstalledOn -Descending | Select-Object HotFixID, Description, InstalledOn
```

## Security-relevant events

### Services installed in the last 7 days

Event 7045. Unexpected new services are a common persistence and lateral movement technique (for
example PsExec-style tools); check the path and the account.

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Id=7045; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Service';e={$_.Properties[0].Value}}, @{n='Path';e={$_.Properties[1].Value}}, @{n='StartType';e={$_.Properties[3].Value}}, @{n='Account';e={$_.Properties[4].Value}}
```

### Scheduled tasks created in the last 7 days

Event 4698. Requires auditing of *Other Object Access Events*.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4698; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Task';e={$_.Properties[4].Value}}, @{n='CreatedBy';e={'{0}\{1}' -f $_.Properties[2].Value, $_.Properties[1].Value}}
```

### Local group membership changes in the last 7 days

Members added to (4732) or removed from (4733) local groups such as Administrators on a member server
or workstation. The member is shown as a SID. On domain controllers these events cover domain local
groups, see [Active Directory events](AD-Events.md).

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4732,4733; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Action';e={@{4732='Added';4733='Removed'}[$_.Id]}}, @{n='Group';e={$_.Properties[2].Value}}, @{n='MemberSid';e={$_.Properties[1].Value}}, @{n='ChangedBy';e={'{0}\{1}' -f $_.Properties[7].Value, $_.Properties[6].Value}}
```

### Local user accounts created or deleted in the last 7 days

On domain controllers this lists domain accounts, see [Active Directory events](AD-Events.md).

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4720,4726; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Action';e={@{4720='Created';4726='Deleted'}[$_.Id]}}, @{n='Account';e={$_.Properties[0].Value}}, @{n='ChangedBy';e={'{0}\{1}' -f $_.Properties[5].Value, $_.Properties[4].Value}}
```

### Event logs cleared

Event 1102 (Security log cleared) and 104 (any other log cleared). Clearing logs is rarely legitimate
on servers and a typical step after an intrusion.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=1102}, @{LogName='System'; ProviderName='Microsoft-Windows-Eventlog'; Id=104} | Select-Object TimeCreated, @{n='Log';e={if ($_.Id -eq 1102) {'Security'} else {$_.Properties[2].Value}}}, @{n='ClearedBy';e={if ($_.Id -eq 1102) {'{0}\{1}' -f $_.Properties[2].Value, $_.Properties[1].Value} else {'{0}\{1}' -f $_.Properties[1].Value, $_.Properties[0].Value}}}
```

### Suspicious PowerShell script blocks in the last 7 days

PowerShell 5.1 logs script blocks that contain suspicious content as warning-level event 4104, even
without script block logging enabled. PowerShell 7 writes to the `PowerShellCore/Operational` log.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-PowerShell/Operational'; Id=4104; Level=3; StartTime=(Get-Date).AddDays(-7)} | Select-Object TimeCreated, @{n='Path';e={$_.Properties[4].Value}}, @{n='ScriptBlock';e={$_.Properties[2].Value}} | Format-List
```

### Microsoft Defender detections in the last 30 days

Events 1116 (malware detected) and 1117 (action taken).

```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational'; Id=1116,1117; StartTime=(Get-Date).AddDays(-30)} | Select-Object TimeCreated, @{n='Event';e={@{1116='Detected';1117='Action taken'}[$_.Id]}}, @{n='Threat';e={$_.Properties[7].Value}}, @{n='Severity';e={$_.Properties[9].Value}}, @{n='User';e={$_.Properties[19].Value}}, @{n='Path';e={$_.Properties[21].Value}}
```

## Log maintenance

### Size and retention of the main logs

`LogMode` `Circular` overwrites the oldest events when the log is full.

```powershell
Get-WinEvent -ListLog Application, Security, System | Select-Object LogName, LogMode, @{n='MaxMB';e={[math]::Round($_.MaximumSizeInBytes / 1MB)}}, @{n='SizeMB';e={[math]::Round($_.FileSize / 1MB)}}, RecordCount, IsEnabled
```

### Oldest event in each log

Shows how far back each log really goes with the current size and retention settings. This is the
oldest record; if the system clock was changed, it can show a later time than newer records.

```powershell
'Application', 'Security', 'System' | ForEach-Object { Get-WinEvent -LogName $_ -Oldest -MaxEvents 1 } | Select-Object LogName, TimeCreated
```

### Largest event logs

```powershell
Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object RecordCount | Sort-Object FileSize -Descending | Select-Object -First 15 LogName, RecordCount, @{n='SizeMB';e={[math]::Round($_.FileSize / 1MB, 1)}}, LogMode
```

### Audit policy in effect

Shows which event categories are audited (success / failure). Requires elevation.

```powershell
auditpol /get /category:*
```

### Export a log to an .evtx file

⚠️ **Writes a file.**

Exports the Security log to a dated file; the target folder must exist. Requires elevation.

```powershell
wevtutil epl Security "C:\Logs\$env:COMPUTERNAME-Security-$(Get-Date -Format yyyyMMdd).evtx"
```

### Read events from an exported .evtx file

All filters on this page also work on exported files with `-Path` instead of `-LogName`.

```powershell
Get-WinEvent -Path "C:\Logs\server01-Security-20250101.evtx" -MaxEvents 50
```

### Increase the maximum size of the Security log

⚠️ **Changes the system.**

Sets the maximum size to 1 GB. Group Policy settings for event log size take precedence.

```powershell
wevtutil sl Security /ms:1073741824
```

---

See also: [Active Directory events](AD-Events.md) for domain controller Security log queries and
[Windows Firewall](Windows-Firewall.md) for firewall rules and logging.
