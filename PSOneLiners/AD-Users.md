# Users and groups

[← Back to index](../README.md)

Everyday user and group management. Commands marked ⚠️ change Active Directory.

- [Count enabled user accounts](#count-enabled-user-accounts)
- [Users inactive for more than 90 days](#users-inactive-for-more-than-90-days)
- [Enabled users that never logged on](#enabled-users-that-never-logged-on)
- [Passwords not changed for more than a year](#passwords-not-changed-for-more-than-a-year)
- [Users created in the last 7 days](#users-created-in-the-last-7-days)
- [Accounts expiring in the next 30 days](#accounts-expiring-in-the-next-30-days)
- [Real last logon time of a user](#real-last-logon-time-of-a-user)
- ⚠️ [Add a user to a group for a limited time](#add-a-user-to-a-group-for-a-limited-time)
- [Check remaining time of temporary memberships](#check-remaining-time-of-temporary-memberships)
- ⚠️ [Copy group memberships from one user to another](#copy-group-memberships-from-one-user-to-another)
- [Enabled user accounts in a group](#enabled-user-accounts-in-a-group)
- [Password expiration date of a user](#password-expiration-date-of-a-user)
- [Locked-out accounts](#locked-out-accounts)
- [Users with a specific proxy address](#users-with-a-specific-proxy-address)

## Users

### Count enabled user accounts

`Get-ADUser` returns user accounts only (computer objects also have `objectClass=user`).

```powershell
Get-ADUser -Filter 'Enabled -eq $true' -SearchBase "DC=example,DC=com" -SearchScope Subtree | Measure-Object
```

## Account lifecycle

### Users inactive for more than 90 days

Enabled users whose last logon is older than 90 days. `LastLogonDate` comes from `lastLogonTimestamp`, which
replicates with a delay of up to 14 days, so it is accurate enough for clean-up but not for auditing.

```powershell
Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00 | Where-Object Enabled | Select-Object Name, SamAccountName, LastLogonDate
```

### Enabled users that never logged on

```powershell
Get-ADUser -LDAPFilter "(&(!(lastLogonTimestamp=*))(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" -Properties whenCreated | Select-Object Name, SamAccountName, whenCreated
```

### Passwords not changed for more than a year

Enabled users whose password was last set more than 365 days ago. Accounts that must change their password
at next logon (`pwdLastSet` = 0) are skipped.

```powershell
Get-ADUser -LDAPFilter "(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(!(pwdLastSet=0))(pwdLastSet<=$((Get-Date).AddDays(-365).ToFileTimeUtc())))" -Properties PasswordLastSet, PasswordNeverExpires | Sort-Object PasswordLastSet | Select-Object Name, SamAccountName, PasswordLastSet, PasswordNeverExpires
```

### Users created in the last 7 days

The time filter is evaluated by the domain controller and does not depend on the regional settings of the
client.

```powershell
Get-ADUser -LDAPFilter "(whenCreated>=$((Get-Date).AddDays(-7).ToUniversalTime().ToString('yyyyMMddHHmmss.0Z')))" -Properties whenCreated | Sort-Object whenCreated -Descending | Select-Object Name, SamAccountName, whenCreated
```

### Accounts expiring in the next 30 days

```powershell
Search-ADAccount -AccountExpiring -UsersOnly -TimeSpan 30.00:00:00 | Select-Object Name, SamAccountName, AccountExpirationDate
```

### Real last logon time of a user

`lastLogon` is updated only on the domain controller that authenticated the user and is not replicated, so
this asks every domain controller. The first line is the most recent logon.

```powershell
Get-ADDomainController -Filter * | ForEach-Object { $dc = $_.HostName; Get-ADUser -Identity UserName -Server $dc -Properties lastLogon | Select-Object @{n='DC';e={$dc}}, @{n='LastLogon';e={[datetime]::FromFileTime($_.lastLogon)}} } | Sort-Object LastLogon -Descending
```

## Time-based group membership

Requires the Privileged Access Management feature, see
[Optional features](AD-Features.md).

### Add a user to a group for a limited time

⚠️ **Changes Active Directory.**

The membership is removed automatically when the time-to-live expires (15 minutes here).

```powershell
Add-ADGroupMember -Identity 'GroupName' -Members 'AccountName' -MemberTimeToLive (New-TimeSpan -Minutes 15)
```

### Check remaining time of temporary memberships

```powershell
Get-ADGroup 'GroupName' -Property member -ShowMemberTimeToLive
```

## Group membership

### Copy group memberships from one user to another

⚠️ **Changes Active Directory.**

Adds `TargetUser` to every group that `SourceUser` is a member of and lists the groups.

```powershell
Get-ADUser -Identity SourceUser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members TargetUser -PassThru | Select-Object -Property SamAccountName
```

### Enabled user accounts in a group

```powershell
Get-AdGroupMember -identity 'GroupName' | get-aduser | Where {$_.Enabled -eq $true}
```

## Passwords and lockouts

### Password expiration date of a user

```powershell
Get-ADUser UserName –Properties DisplayName, msDS-UserPasswordExpiryTimeComputed | Select-Object -Property Displayname,@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
```

### Locked-out accounts

Lists enabled accounts that are currently locked out and whose last logon is older than 3 days
(adjust `AddDays(-3)`). Remove the `#` before `| unlock-adaccount` to unlock them (⚠️).

```powershell
Search-ADAccount -lockedout | where-object {($_.enabled -eq 'True') -and ($_.LastLogonDate -lt (Get-Date).AddDays(-3))} # | unlock-adaccount
```

## Mail attributes

### Users with a specific proxy address

```powershell
Get-AdUser -Filter * -Properties ProxyAddresses | where-object {$_.ProxyAddresses -like '*user@example.com*'}
```

---

See also: [Active Directory events](AD-Events.md) for account lockout sources and password resets.
