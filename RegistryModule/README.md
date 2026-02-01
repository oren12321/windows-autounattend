# PowerShell Registry Management & Provisioning Framework

A professional-grade toolkit for declarative registry orchestration, specifically designed for **Windows Image Customization**, **Automated Deployment Scripts**, and **User Profile Provisioning**.

This framework provides surgical control over registry states, including bit-level manipulation and a scoped placement engine to determine whether settings belong in the System (HKLM), Default User Hive (for new profiles), or specific User Profiles.

## Key Features

- **Surgical Bit/Byte Editing**: Modify binary buffers without overwriting adjacent data.
- **Smart Scoping Engine**: Automatically routes registry keys to the correct deployment phase.
- **Default User Hive Support**: Seamlessly remaps `HKCU` paths to a mounted `HKEY_USERS` hive.
- **Batch Processing**: Apply large configuration sets efficiently using PowerShell splatting.
- **MIT Licensed**: Permissive licensing for corporate and private environments.

---

## Scoping Algorithm

The framework utilizes `Test-RegistryPlacement` to categorize registry paths into specific deployment **Scopes**. This prevents system instability by ensuring keys are only applied where they are valid.

| Scope | Context | Target Logic |
| :--- | :--- | :--- |
| **SYSTEM** | Machine Level | Targets `HKLM` or global Policy overrides (`HKCU\Software\Policies`). |
| **DefaultUser** | Image Template | Targets the `NTUSER.DAT` template used to create all new user profiles. |
| **FirstUser** | Initial Setup | Targets user-specific keys that are sensitive to "First Run" logic (AppX, Search, MRU). |
| **PerUser** | Active Session | Targets generic user preferences and application settings. |

### Algorithmic Hierarchy:
1.  **Hard Policies**: Paths containing `\Policies\` are strictly mapped to **SYSTEM**.
2.  **Autoruns**: `Run` and `RunOnce` keys are permitted across **DefaultUser**, **FirstUser**, and **PerUser** to ensure app persistence.
3.  **Volatile/History**: MRU (Most Recently Used), UserAssist, and History keys are restricted to **FirstUser** to avoid "dirty" profile templates.
4.  **Modern Shell**: AppX and Package-related keys are strictly **FirstUser** to prevent Sysprep failures.
5.  **Fallback**: Generic `HKCU` paths default to **DefaultUser** and **PerUser** availability.

---

## Function Reference

### Core Logic
*   `Apply-RegistryEntry`: The primary engine. Supports `Set`, `Delete`, `SetByte`, and `SetBit`.
*   `Apply-RegistryBatch`: Iterates through an array of hashtables to apply bulk changes.

### Scoping & Filtering
*   `Test-RegistryPlacement`: Returns `$true` if a path is valid for a given scope.
*   `Get-EntriesForScope`: Filters a master list of entries based on the target deployment phase.

### Hive Provisioning
*   `Convert-EntriesToDefaultUserHive`: Replaces the `HKCU:` provider prefix with a custom mount point path.

---

## Usage Guide

### 1. Basic Batch Application
```powershell
$Settings = @(
    @{ Path = "HKCU:\Software\App"; Name = "Theme"; Value = "Dark"; Operation = "Set"; Type = "String" }
)
Apply-RegistryBatch -Items $Settings
```

### 2. Surgical Bit Manipulation
```powershell
# Toggle only the 5th bit of the first byte in a binary array
Apply-RegistryEntry -Path "HKCU:\Control Panel\Desktop" -Operation "SetBit" -Name "UserPreferencesMask" -Offset 0 -BitIndex 5 -BitValue 1
```

### 3. Provisioning a Default User Hive (Workflow)
To apply settings to the Windows Default User template, you must load the hive, convert the paths, and then unload it.

```powershell
# Step 1: Load the Hive
reg load "HKEY_USERS\DefaultUser" "C:\Users\Default\NTUSER.DAT"

# Step 2: Filter and Convert
$MasterList = Import-MyRegistryConfigs # Your source array
$Filtered = Get-EntriesForScope -Entries $MasterList -Scope 'DefaultUser'
$Converted = Convert-EntriesToDefaultUserHive -Entries $Filtered -MountPoint "Registry::HKEY_USERS\DefaultUser"

# Step 3: Apply
Apply-RegistryBatch -Items $Converted

# Step 4: Unload
[GC]::Collect() # Release file handles
reg unload "HKEY_USERS\DefaultUser"
```

---

## Requirements
- **PowerShell 5.1+**
- **Administrative Privileges**: Required for [Registry Hive Loading](https://learn.microsoft.com) and `HKLM` modifications.

## License
**MIT License**

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

