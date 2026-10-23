# Repadmin

[← Back to index](../README.md)

Not PowerShell, but still the quickest way to troubleshoot Active Directory replication.
`repadmin.exe` is available on domain controllers and with the RSAT AD DS tools. Run it from an
elevated prompt.

## Step-by-step replication troubleshooting

### Step 1 – Check replication health

Summary of replication status for all domain controllers.

```powershell
Repadmin /replsummary
```

### Step 2 – Check queued inbound replication requests

```powershell
Repadmin /Queue
```

### Step 3 – Check replication status

```powershell
Repadmin /Showrepl
```

### Step 4 – Synchronize replication between partners

⚠️ **Changes Active Directory.**

Triggers replication with all partners of the domain controller.

```powershell
Repadmin /syncall
```

### Step 5 – Force the KCC to recalculate the topology

⚠️ **Changes Active Directory.**

```powershell
Repadmin /KCC
```

### Step 6 – Force replication

⚠️ **Changes Active Directory.**

Without arguments the command prints its syntax; it expects the destination DC, source DC and
naming context: `repadmin /replicate <DestinationDC> <SourceDC> <NamingContext>`.

```powershell
Repadmin /replicate
```

### Step 7 – Show only errors

```powershell
repadmin /showrepl /errorsonly
```

---

See also: [Health and replication](AD-Health.md) for the PowerShell equivalents.
