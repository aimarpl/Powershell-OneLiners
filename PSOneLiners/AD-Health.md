# Health and replication

[← Back to index](../README.md)

Quick checks of domain controllers, replication and forest settings with the ActiveDirectory module
and the built-in tools `dcdiag`, `w32tm`, `nltest` and `dfsrmig`. All commands on this page are read-only.

- [Get all domain controllers](#get-all-domain-controllers)
- [Inbound replication partners of a domain controller](#inbound-replication-partners-of-a-domain-controller)
- [Inbound replication partners for a domain](#inbound-replication-partners-for-a-domain)
- [Replication failures of a domain controller](#replication-failures-of-a-domain-controller)
- [Replication failures for a domain](#replication-failures-for-a-domain)
- [Replication failures for a forest](#replication-failures-for-a-forest)
- [Replication failures for a site](#replication-failures-for-a-site)
- [Run dcdiag and show only errors](#run-dcdiag-and-show-only-errors)
- [Time offset of all domain controllers](#time-offset-of-all-domain-controllers)
- [Time source of a domain controller](#time-source-of-a-domain-controller)
- [Domain controller used by this computer](#domain-controller-used-by-this-computer)
- [SYSVOL replication state (FRS or DFSR)](#sysvol-replication-state-frs-or-dfsr)
- [Forest and domain functional levels](#forest-and-domain-functional-levels)
- [Schema version](#schema-version)
- [Tombstone lifetime](#tombstone-lifetime)
- [Sites and subnets](#sites-and-subnets)

## Domain controllers

### Get all domain controllers

Lists every domain controller and whether it is a Global Catalog server.

```powershell
Get-ADDomainController –Filter * | Select Hostname, IsGlobalCatalog
```

## Replication partners

### Inbound replication partners of a domain controller

Shows replication partner metadata (last attempt, last success, partner) for one domain
controller.

```powershell
Get-ADReplicationPartnerMetadata -Target "dc01.example.com"
```

### Inbound replication partners for a domain

Same as above for every domain controller in the domain.

```powershell
Get-ADReplicationPartnerMetadata -Target "example.com" -Scope Domain
```

## Replication failures

`Get-ADReplicationFailure` accepts a domain controller, domain, forest or site as the target.

### Replication failures of a domain controller

```powershell
Get-ADReplicationFailure -Target "dc01.example.com"
```

### Replication failures for a domain

```powershell
Get-ADReplicationFailure -Target "example.com" -Scope Domain
```

### Replication failures for a forest

```powershell
Get-ADReplicationFailure -Target "example.com" -Scope Forest
```

### Replication failures for a site

```powershell
Get-ADReplicationFailure -Target "Default-First-Site-Name" -Scope Site
```

## Domain controller diagnostics

### Run dcdiag and show only errors

Runs the standard tests against one domain controller. Use `/e` instead of `/s:` to test every domain
controller in the forest (can take several minutes).

```powershell
dcdiag /s:dc01.example.com /q
```

### Time offset of all domain controllers

Kerberos fails when clocks differ by more than 5 minutes.

```powershell
w32tm /monitor /domain:example.com
```

### Time source of a domain controller

The PDC emulator of the forest root domain should use a reliable external source; all other domain
controllers should sync from the domain hierarchy.

```powershell
w32tm /query /computer:dc01.example.com /source
```

### Domain controller used by this computer

```powershell
nltest /dsgetdc:example.com
```

### SYSVOL replication state (FRS or DFSR)

`Eliminated` means SYSVOL is replicated with DFSR. FRS is not supported on Windows Server 2019 and later.

```powershell
dfsrmig /getglobalstate
```

## Forest and domain

### Forest and domain functional levels

```powershell
[pscustomobject]@{ ForestMode = (Get-ADForest).ForestMode; DomainMode = (Get-ADDomain).DomainMode }
```

### Schema version

`objectVersion` 87 = Windows Server 2016, 88 = Windows Server 2019 / 2022, 91 = Windows Server 2025.

```powershell
Get-ADObject -Identity (Get-ADRootDSE).schemaNamingContext -Properties objectVersion | Select-Object objectVersion
```

### Tombstone lifetime

Days a deleted object is kept, and the maximum age of a backup that can be restored. Empty means 60 days.

```powershell
(Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$((Get-ADRootDSE).configurationNamingContext)" -Properties tombstoneLifetime).tombstoneLifetime
```

### Sites and subnets

Clients whose IP address is not in any subnet cannot find the domain controllers of their site.

```powershell
Get-ADReplicationSubnet -Filter * | Select-Object Name, @{n='Site';e={($_.Site -split ',')[0] -replace '^CN='}} | Sort-Object Site, Name
```

---

See also: [Repadmin](repadmin.md) for replication troubleshooting with `repadmin.exe`.
