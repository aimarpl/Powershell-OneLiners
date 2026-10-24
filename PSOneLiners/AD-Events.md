# Active Directory events

[← Back to index](../README.md)

Security log queries on domain controllers: account lockouts, failed authentication, group membership
and account changes, and Kerberos tickets with weak encryption. All commands on this page are read-only.

- Each domain controller logs only the requests it processed, so most queries loop over all domain
  controllers with `Get-ADDomainController -Filter *`.
- Reading the Security log of a domain controller requires Domain Admins or membership in
  *Event Log Readers* on the domain controllers, and the *Remote Event Log Management* firewall rule.
- The events depend on the domain controller audit policy (*Account Management*, *Account Logon*,
  *Kerberos Service Ticket Operations*). Check it on a domain controller with `auditpol /get /category:*`.
- `-ErrorAction SilentlyContinue` skips domain controllers without matching events, but also hides
  connection and access errors. Remove it when a domain controller seems to be missing from the results.

- [Account lockouts in the last 24 hours and their source](#account-lockouts-in-the-last-24-hours-and-their-source)
- [Failed Kerberos pre-authentication for a user](#failed-kerberos-pre-authentication-for-a-user)
- [Failed NTLM authentication in the last 24 hours](#failed-ntlm-authentication-in-the-last-24-hours)
- [Group membership changes in the last 7 days](#group-membership-changes-in-the-last-7-days)
- [User and computer accounts created or deleted in the last 7 days](#user-and-computer-accounts-created-or-deleted-in-the-last-7-days)
- [Password resets, changes and unlocks in the last 7 days](#password-resets-changes-and-unlocks-in-the-last-7-days)
- [Kerberos service tickets with RC4 encryption in the last 24 hours](#kerberos-service-tickets-with-rc4-encryption-in-the-last-24-hours)

## Lockouts and failed authentication

### Account lockouts in the last 24 hours and their source

Lockouts (event 4740) are always processed by the PDC emulator. `CallerComputer` is the machine that
sent the bad passwords, typically a device or service with a stale saved password.

```powershell
Get-WinEvent -ComputerName (Get-ADDomain).PDCEmulator -FilterHashtable @{LogName='Security'; Id=4740; StartTime=(Get-Date).AddDays(-1)} | Select-Object TimeCreated, @{n='User';e={$_.Properties[0].Value}}, @{n='CallerComputer';e={$_.Properties[1].Value}}
```

### Failed Kerberos pre-authentication for a user

Event 4771 on all domain controllers for `UserName` in the last 24 hours. Status `0x18` means a wrong
password; `ClientIP` shows where the attempts come from.

```powershell
Get-ADDomainController -Filter * | ForEach-Object { Get-WinEvent -ComputerName $_.HostName -LogName Security -FilterXPath "*[System[EventID=4771 and TimeCreated[timediff(@SystemTime) <= 86400000]] and EventData[Data[@Name='TargetUserName']='UserName']]" -ErrorAction SilentlyContinue } | Select-Object TimeCreated, MachineName, @{n='ClientIP';e={$_.Properties[6].Value}}, @{n='Status';e={$_.Properties[4].Value}}
```

### Failed NTLM authentication in the last 24 hours

Event 4776 with a non-zero status on all domain controllers, grouped by account and workstation.
Status `0xC000006A` means a wrong password, `0xC0000064` an unknown account.

```powershell
Get-ADDomainController -Filter * | ForEach-Object { Get-WinEvent -ComputerName $_.HostName -LogName Security -FilterXPath "*[System[EventID=4776 and TimeCreated[timediff(@SystemTime) <= 86400000]] and EventData[Data[@Name='Status']!='0x0']]" -ErrorAction SilentlyContinue } | Group-Object {$_.Properties[1].Value}, {$_.Properties[2].Value}, {'0x{0:X8}' -f $_.Properties[3].Value} | Sort-Object Count -Descending | Select-Object Count, Name
```

## Group and account changes

### Group membership changes in the last 7 days

Members added to or removed from global (4728/4729), domain local (4732/4733) and universal (4756/4757)
security groups, from all domain controllers. Members without a name (for example well-known groups) are
shown as a SID. Append `| Where-Object Group -match 'Admins|Operators'`
to show privileged groups only.

```powershell
Get-ADDomainController -Filter * | ForEach-Object { Get-WinEvent -ComputerName $_.HostName -FilterHashtable @{LogName='Security'; Id=4728,4729,4732,4733,4756,4757; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue } | Sort-Object TimeCreated | Select-Object TimeCreated, @{n='Action';e={if ($_.Id % 2) {'Removed'} else {'Added'}}}, @{n='Group';e={$_.Properties[2].Value}}, @{n='Member';e={if ($_.Properties[0].Value -and $_.Properties[0].Value -ne '-') {$_.Properties[0].Value} else {"$($_.Properties[1].Value)"}}}, @{n='ChangedBy';e={$_.Properties[6].Value}}, MachineName
```

### User and computer accounts created or deleted in the last 7 days

```powershell
Get-ADDomainController -Filter * | ForEach-Object { Get-WinEvent -ComputerName $_.HostName -FilterHashtable @{LogName='Security'; Id=4720,4726,4741,4743; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue } | Sort-Object TimeCreated | Select-Object TimeCreated, @{n='Action';e={@{4720='User created';4726='User deleted';4741='Computer created';4743='Computer deleted'}[$_.Id]}}, @{n='Account';e={$_.Properties[0].Value}}, @{n='ChangedBy';e={$_.Properties[4].Value}}, MachineName
```

### Password resets, changes and unlocks in the last 7 days

Event 4724 is a reset by someone else (for example the help desk), 4723 a change by the user, 4767 an
account unlock.

```powershell
Get-ADDomainController -Filter * | ForEach-Object { Get-WinEvent -ComputerName $_.HostName -FilterHashtable @{LogName='Security'; Id=4723,4724,4767; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue } | Sort-Object TimeCreated | Select-Object TimeCreated, @{n='Action';e={@{4723='Password changed';4724='Password reset';4767='Account unlocked'}[$_.Id]}}, @{n='Account';e={$_.Properties[0].Value}}, @{n='ChangedBy';e={$_.Properties[4].Value}}, MachineName
```

## Kerberos

### Kerberos service tickets with RC4 encryption in the last 24 hours

Service tickets (event 4769) issued with RC4 (`0x17`) for user accounts. They show which services still
need RC4 and are the typical footprint of Kerberoasting, where an attacker requests RC4 tickets to crack
the service account password offline. Computer accounts (ending in `$`) are filtered out.

```powershell
Get-ADDomainController -Filter * | ForEach-Object { Get-WinEvent -ComputerName $_.HostName -LogName Security -FilterXPath "*[System[EventID=4769 and TimeCreated[timediff(@SystemTime) <= 86400000]] and EventData[Data[@Name='TicketEncryptionType']='0x17']]" -ErrorAction SilentlyContinue } | Where-Object { $_.Properties[2].Value -notlike '*$' } | Group-Object {$_.Properties[2].Value}, {$_.Properties[0].Value} | Sort-Object Count -Descending | Select-Object Count, @{n='Service, RequestedBy';e={$_.Name}}
```

---

See also: [Windows event logs](Windows-Events.md) for logons, restarts and software on any Windows
computer, and [Users and groups](AD-Users.md#locked-out-accounts) for locked-out accounts.
