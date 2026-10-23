# Users and groups

[← Back to index](../README.md)

Everyday user and group management. Commands marked ⚠️ change Active Directory.

- [Count enabled user accounts](#count-enabled-user-accounts)
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
