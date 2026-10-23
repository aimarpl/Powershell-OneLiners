# Optional features

[← Back to index](../README.md)

Active Directory optional features that unlock additional functionality, and the Active Directory Recycle
Bin for restoring deleted objects.

- [Status of the optional features](#status-of-the-optional-features)
- ⚠️ [Enable the Privileged Access Management feature](#enable-the-privileged-access-management-feature)
- ⚠️ [Enable the Recycle Bin](#enable-the-recycle-bin)
- [Recently deleted objects](#recently-deleted-objects)
- ⚠️ [Restore a deleted user](#restore-a-deleted-user)

## Status

### Status of the optional features

`Enabled` is `True` when the feature is enabled for the forest.

```powershell
Get-ADOptionalFeature -Filter * | Select-Object Name, @{n='Enabled';e={[bool]$_.EnabledScopes}}
```

## Privileged Access Management

### Enable the Privileged Access Management feature

⚠️ **Changes Active Directory.**

Enables time-based (temporary) group membership, used by `Add-ADGroupMember -MemberTimeToLive`
on the [Users and groups](AD-Users.md#time-based-group-membership) page.

```powershell
Enable-ADOptionalFeature ‘Privileged Access Management Feature’ -Scope ForestOrConfigurationSet -Target example.com
```

> [!CAUTION]
> Enabling this feature is **irreversible** and requires the Windows Server 2016 forest
> functional level (or newer). Plan it as a forest-wide change.

## Recycle Bin

### Enable the Recycle Bin

⚠️ **Changes Active Directory.**

Deleted objects keep all their attributes and group memberships and can be restored with
`Restore-ADObject`.

```powershell
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target example.com
```

> [!CAUTION]
> Enabling the Recycle Bin is **irreversible** and requires the Windows Server 2008 R2 forest
> functional level (or newer).

### Recently deleted objects

```powershell
Get-ADObject -Filter 'isDeleted -eq $true -and Name -ne "Deleted Objects"' -IncludeDeletedObjects -Properties whenChanged, lastKnownParent | Sort-Object whenChanged -Descending | Select-Object Name, ObjectClass, whenChanged, LastKnownParent
```

### Restore a deleted user

⚠️ **Changes Active Directory.**

Restores `UserName` to its last known parent. If the parent OU was deleted too, restore the OU first.

```powershell
Get-ADObject -Filter 'samAccountName -eq "UserName"' -IncludeDeletedObjects | Restore-ADObject
```
