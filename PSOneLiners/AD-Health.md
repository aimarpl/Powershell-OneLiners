# Health and replication

[← Back to index](../README.md)

Quick checks of domain controllers and Active Directory replication with the ActiveDirectory
module. All commands on this page are read-only.

- [Get all domain controllers](#get-all-domain-controllers)
- [Inbound replication partners of a domain controller](#inbound-replication-partners-of-a-domain-controller)
- [Inbound replication partners for a domain](#inbound-replication-partners-for-a-domain)
- [Replication failures of a domain controller](#replication-failures-of-a-domain-controller)
- [Replication failures for a domain](#replication-failures-for-a-domain)
- [Replication failures for a forest](#replication-failures-for-a-forest)
- [Replication failures for a site](#replication-failures-for-a-site)

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

---

See also: [Repadmin](repadmin.md) for replication troubleshooting with `repadmin.exe`.
