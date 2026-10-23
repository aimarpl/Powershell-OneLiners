# Optional features

[← Back to index](../README.md)

Active Directory optional features that unlock additional functionality.

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
