# Security

[← Back to index](../README.md)

Audit queries for stale accounts, risky account settings, privileged groups and service
accounts. All commands on this page are read-only.

- [Computer accounts inactive for more than 180 days](#computer-accounts-inactive-for-more-than-180-days)
- [User accounts allowed to have an empty password](#user-accounts-allowed-to-have-an-empty-password)
- [Accounts with PasswordNeverExpires enabled](#accounts-with-passwordneverexpires-enabled)
- [Groups with adminCount set to 1](#groups-with-admincount-set-to-1)
- [Computers running a specific operating system](#computers-running-a-specific-operating-system)
- [User accounts with SPNs (Kerberoasting exposure)](#user-accounts-with-spns-kerberoasting-exposure)

## Stale and risky accounts

### Computer accounts inactive for more than 180 days

`-TimeSpan` takes a time span (`days.hours:minutes:seconds`); a plain number would be read as
ticks, not days.

```powershell
Search-ADaccount -ComputersOnly -AccountInactive -Timespan 180.00:00:00
```

### User accounts allowed to have an empty password

Finds users with the `PASSWD_NOTREQD` flag (userAccountControl bit 32).

```powershell
get-adobject -ldapfilter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))" -properties useraccountcontrol
```

### Accounts with PasswordNeverExpires enabled

```powershell
Search-ADAccount -PasswordNeverExpires | ft samaccountname,name,enabled
```

## Privileged access

### Groups with adminCount set to 1

Groups that are, or were, protected by AdminSDHolder, which usually means administrative
rights.

```powershell
Get-ADGroup –LDAPFilter “(admincount=1)”
```

### Computers running a specific operating system

Useful for finding unsupported systems. Change the `OperatingSystem` pattern as needed.

```powershell
Get-ADComputer -Filter {OperatingSystem -Like "Windows Server 2008*"} -Property * | Format-Table Name,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion -Wrap -Auto
```

### User accounts with SPNs (Kerberoasting exposure)

User accounts with a `servicePrincipalName` can be targeted by Kerberoasting; make sure they
use long, random passwords or group Managed Service Accounts.

```powershell
dsquery * "dc=example,dc=com" -filter "(&(objectcategory=user)(servicePrincipalName=*))" -attr distinguishedName servicePrincipalName
```
