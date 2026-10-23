# FSMO roles

[← Back to index](../README.md)

Find which domain controllers hold the five operations master (FSMO) roles and transfer a role
to another domain controller.

## Find role holders

### Forest-wide roles: Domain Naming Master and Schema Master

```powershell
Get-ADForest example.com | fl DomainNamingMaster, SchemaMaster
```

### Domain-wide roles: Infrastructure Master, PDC Emulator and RID Master

```powershell
Get-ADDomain example.com | fl InfrastructureMaster, PDCEmulator, RIDMaster
```

## Transfer a role

### Move a role to another domain controller

⚠️ **Changes Active Directory.**

Transfers a role to the domain controller `New-Host`. Replace `RoleName` with one of
`PDCEmulator`, `RIDMaster`, `InfrastructureMaster`, `SchemaMaster` or `DomainNamingMaster`
(several roles can be passed as a comma-separated list).

```powershell
Move-ADDirectoryServerOperationMasterRole -Identity "New-Host" RoleName
```

> [!WARNING]
> Transferring the Schema Master or Domain Naming Master requires Enterprise Admins rights.
> Use `-Force` (seizing a role) only when the current role holder is permanently offline.
