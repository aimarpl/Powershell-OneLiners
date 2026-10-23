# Security

[← Back to index](../README.md)

Audit queries for stale accounts, risky account settings, privileged access, Kerberos delegation and
domain-wide security settings. All commands on this page are read-only.

- [Computer accounts inactive for more than 180 days](#computer-accounts-inactive-for-more-than-180-days)
- [User accounts allowed to have an empty password](#user-accounts-allowed-to-have-an-empty-password)
- [Accounts with PasswordNeverExpires enabled](#accounts-with-passwordneverexpires-enabled)
- [Users that do not require Kerberos pre-authentication (AS-REP roasting)](#users-that-do-not-require-kerberos-pre-authentication-as-rep-roasting)
- [Accounts that store passwords with reversible encryption](#accounts-that-store-passwords-with-reversible-encryption)
- [Accounts limited to DES encryption](#accounts-limited-to-des-encryption)
- [Accounts with SID history](#accounts-with-sid-history)
- [Groups with adminCount set to 1](#groups-with-admincount-set-to-1)
- [Members of privileged groups](#members-of-privileged-groups)
- [Privileged accounts that can be delegated](#privileged-accounts-that-can-be-delegated)
- [Members of Protected Users](#members-of-protected-users)
- [Age of the krbtgt password](#age-of-the-krbtgt-password)
- [Computers running a specific operating system](#computers-running-a-specific-operating-system)
- [Enabled computers per operating system](#enabled-computers-per-operating-system)
- [User accounts with SPNs (Kerberoasting exposure)](#user-accounts-with-spns-kerberoasting-exposure)
- [Accounts trusted for unconstrained delegation](#accounts-trusted-for-unconstrained-delegation)
- [Accounts with constrained delegation](#accounts-with-constrained-delegation)
- [Computers with resource-based constrained delegation](#computers-with-resource-based-constrained-delegation)
- [Default domain password policy](#default-domain-password-policy)
- [Fine-grained password policies](#fine-grained-password-policies)
- [Who can join computers to the domain (MachineAccountQuota)](#who-can-join-computers-to-the-domain-machineaccountquota)
- [Members of Pre-Windows 2000 Compatible Access](#members-of-pre-windows-2000-compatible-access)
- [Domain and forest trusts](#domain-and-forest-trusts)
- [Computers without a Windows LAPS password](#computers-without-a-windows-laps-password)
- [Group Policy objects changed in the last 7 days](#group-policy-objects-changed-in-the-last-7-days)
- [Privileged groups changed in the last 7 days](#privileged-groups-changed-in-the-last-7-days)

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

### Users that do not require Kerberos pre-authentication (AS-REP roasting)

Enabled users with `DONT_REQ_PREAUTH` (userAccountControl bit 4194304). Anyone can request data encrypted
with their password hash and crack it offline.

```powershell
Get-ADUser -LDAPFilter "(&(userAccountControl:1.2.840.113556.1.4.803:=4194304)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" | Select-Object Name, SamAccountName
```

### Accounts that store passwords with reversible encryption

userAccountControl bit 128: the password is stored in a form that can be decrypted.

```powershell
Get-ADUser -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=128)" | Select-Object Name, SamAccountName, Enabled
```

### Accounts limited to DES encryption

userAccountControl bit 2097152 (`USE_DES_KEY_ONLY`). DES is disabled by default since Windows Server 2008 R2.

```powershell
Get-ADObject -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=2097152)" | Select-Object Name, ObjectClass, DistinguishedName
```

### Accounts with SID history

`sIDHistory` grants the rights of the old SIDs. Expected only during migrations; otherwise a persistence
technique.

```powershell
Get-ADObject -LDAPFilter "(sIDHistory=*)" -Properties sIDHistory | Select-Object Name, ObjectClass, @{n='SIDHistory';e={$_.sIDHistory -join ', '}}
```

## Privileged access

### Groups with adminCount set to 1

Groups that are, or were, protected by AdminSDHolder, which usually means administrative
rights.

```powershell
Get-ADGroup –LDAPFilter “(admincount=1)”
```

### Members of privileged groups

Recursive members of Domain Admins, Enterprise Admins, Schema Admins, Administrators, Account Operators,
Server Operators, Print Operators and Backup Operators. The groups are found by SID, so the query also works
with localized group names. Enterprise Admins and Schema Admins exist only in the forest root domain.

```powershell
$sid = (Get-ADDomain).DomainSID.Value; Get-ADGroup -LDAPFilter "(|(objectSid=$sid-512)(objectSid=$sid-519)(objectSid=$sid-518)(objectSid=S-1-5-32-544)(objectSid=S-1-5-32-548)(objectSid=S-1-5-32-549)(objectSid=S-1-5-32-550)(objectSid=S-1-5-32-551))" | ForEach-Object { $g = $_.Name; Get-ADGroupMember -Identity $_ -Recursive | Select-Object @{n='Group';e={$g}}, Name, SamAccountName, objectClass }
```

### Privileged accounts that can be delegated

Enabled users with `adminCount=1` without *Account is sensitive and cannot be delegated*. Their credentials
can be forwarded by any service trusted for delegation; set the flag or add them to Protected Users.

```powershell
Get-ADUser -LDAPFilter "(&(adminCount=1)(!(userAccountControl:1.2.840.113556.1.4.803:=1048576))(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" | Select-Object Name, SamAccountName
```

### Members of Protected Users

```powershell
Get-ADGroupMember -Identity "$((Get-ADDomain).DomainSID)-525" | Select-Object Name, SamAccountName, objectClass
```

### Age of the krbtgt password

The krbtgt key signs every Kerberos ticket. Reset it regularly (twice, with replication in between) and after
any suspected compromise of a domain controller.

```powershell
Get-ADUser -Identity krbtgt -Properties PasswordLastSet | Select-Object Name, PasswordLastSet, @{n='AgeDays';e={((Get-Date) - $_.PasswordLastSet).Days}}
```

### Computers running a specific operating system

Useful for finding unsupported systems. Change the `OperatingSystem` pattern as needed.

```powershell
Get-ADComputer -Filter {OperatingSystem -Like "Windows Server 2008*"} -Property * | Format-Table Name,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion -Wrap -Auto
```

### Enabled computers per operating system

```powershell
Get-ADComputer -Filter 'Enabled -eq $true' -Properties OperatingSystem | Group-Object OperatingSystem | Sort-Object Count -Descending | Select-Object Count, Name
```

### User accounts with SPNs (Kerberoasting exposure)

User accounts with a `servicePrincipalName` can be targeted by Kerberoasting; make sure they
use long, random passwords or group Managed Service Accounts.

```powershell
dsquery * "dc=example,dc=com" -filter "(&(objectcategory=user)(servicePrincipalName=*))" -attr distinguishedName servicePrincipalName
```

## Delegation

### Accounts trusted for unconstrained delegation

Users and computers other than domain controllers with `TRUSTED_FOR_DELEGATION` (bit 524288). Any account
that authenticates to them leaves a forwardable ticket behind, including domain admins.

```powershell
Get-ADObject -LDAPFilter "(&(userAccountControl:1.2.840.113556.1.4.803:=524288)(!(primaryGroupID=516)))" | Select-Object Name, ObjectClass, DistinguishedName
```

### Accounts with constrained delegation

`ProtocolTransition` = `True` means the account can impersonate any user without their password
(*Use any authentication protocol*).

```powershell
Get-ADObject -LDAPFilter "(msDS-AllowedToDelegateTo=*)" -Properties msDS-AllowedToDelegateTo, userAccountControl | Select-Object Name, ObjectClass, @{n='ProtocolTransition';e={[bool]($_.userAccountControl -band 16777216)}}, @{n='DelegateTo';e={$_.'msDS-AllowedToDelegateTo' -join ', '}}
```

### Computers with resource-based constrained delegation

Shows which accounts may impersonate users to each computer. Unexpected entries are a common privilege
escalation path.

```powershell
Get-ADComputer -LDAPFilter "(msDS-AllowedToActOnBehalfOfOtherIdentity=*)" -Properties PrincipalsAllowedToDelegateToAccount | Select-Object Name, @{n='AllowedPrincipals';e={$_.PrincipalsAllowedToDelegateToAccount -join ', '}}
```

## Domain settings

### Default domain password policy

```powershell
Get-ADDefaultDomainPasswordPolicy | Select-Object MinPasswordLength, PasswordHistoryCount, MaxPasswordAge, ComplexityEnabled, LockoutThreshold, LockoutDuration, ReversibleEncryptionEnabled
```

### Fine-grained password policies

```powershell
Get-ADFineGrainedPasswordPolicy -Filter * | Select-Object Name, Precedence, MinPasswordLength, LockoutThreshold, @{n='AppliesTo';e={$_.AppliesTo -join '; '}}
```

### Who can join computers to the domain (MachineAccountQuota)

The default of 10 lets every user create up to 10 computer accounts. Set it to 0 and delegate joining to
specific groups instead.

```powershell
Get-ADObject -Identity (Get-ADDomain).DistinguishedName -Properties ms-DS-MachineAccountQuota | Select-Object ms-DS-MachineAccountQuota
```

### Members of Pre-Windows 2000 Compatible Access

Members get broad read access to users and groups. `CN=S-1-1-0` (Everyone) or `CN=S-1-5-7` (Anonymous
Logon) allow anonymous enumeration of the directory.

```powershell
(Get-ADGroup -Identity 'S-1-5-32-554' -Properties member).member
```

### Domain and forest trusts

Check the direction and that SID filtering (quarantine) is enabled on external trusts.

```powershell
Get-ADTrust -Filter * | Select-Object Name, Direction, TrustType, ForestTransitive, SelectiveAuthentication, SIDFilteringQuarantined, SIDFilteringForestAware
```

### Computers without a Windows LAPS password

Enabled computers other than domain controllers without a Windows LAPS password expiration time, i.e. not
managed by Windows LAPS. Requires the Windows LAPS schema extension; for legacy Microsoft LAPS use the
attribute `ms-Mcs-AdmPwdExpirationTime`.

```powershell
Get-ADComputer -LDAPFilter "(&(!(msLAPS-PasswordExpirationTime=*))(!(userAccountControl:1.2.840.113556.1.4.803:=2))(!(primaryGroupID=516))(!(primaryGroupID=521)))" | Select-Object Name, DistinguishedName
```

## Recent changes

### Group Policy objects changed in the last 7 days

Requires the GroupPolicy module (RSAT Group Policy Management Tools).

```powershell
Get-GPO -All | Where-Object ModificationTime -gt (Get-Date).AddDays(-7) | Sort-Object ModificationTime -Descending | Select-Object DisplayName, ModificationTime, Owner
```

### Privileged groups changed in the last 7 days

Groups with `adminCount=1` whose object changed recently, for example a new member. `whenChanged` is kept
per domain controller; see [Active Directory events](AD-Events.md#group-membership-changes-in-the-last-7-days)
for who changed what.

```powershell
Get-ADGroup -LDAPFilter "(&(adminCount=1)(whenChanged>=$((Get-Date).AddDays(-7).ToUniversalTime().ToString('yyyyMMddHHmmss.0Z'))))" -Properties whenChanged | Select-Object Name, whenChanged
```

---

See also: [Active Directory events](AD-Events.md) for lockouts, group changes and RC4 Kerberos tickets in the
domain controller Security logs.
