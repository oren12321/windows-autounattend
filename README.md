# 📦 Stowage
**The Explicit PowerShell Workspace Orchestrator**

**Stowage** is a recursive build and packaging tool for PowerShell projects. Unlike standard module managers, Stowage follows a **"Pure & Encapsulated"** philosophy: it mirrors your internal project structure and inlines external dependencies into localized `Shared` folders.

## 🚀 Key Features
*   **Composite Orchestration**: Use the `SubProjects` field to map complex internal folder trees.
*   **Localized Inlining**: Every project gets its own private `Shared` folder for external dependencies.
*   **Collision Guard**: Atomic pre-build validation prevents naming conflicts and missing files.
*   **Identity Aliasing**: Rename dependencies on the fly to resolve conflicts or simplify paths.
*   **Path Mapping**: Automatically generates `Paths.ps1` for easy, relative dependency loading.
*   **PS 5.1 Native**: Works out-of-the-box on a fresh Windows installation.

---

## 🛠 How to Configure `Manifest.psd1`
Every folder in your tree must contain a `Manifest.psd1`. Stowage uses two primary fields to understand your project:

### 1. `SubProjects` (Internal)
Used for folders that are part of your own repository. These are mirrored to the build folder as-is.
```powershell
SubProjects = @(
    "src/Core",
    "src/Ui"
)
```

### 2. `Dependencies` (External)
Used for "foreign" code or assets. These are copied into a `Shared` folder at the project's level.
```powershell
Dependencies = @(
    "../External/Logger",               # Standard Project
    "../Assets/config.json",            # Static File Asset
    @{ Name="Net"; Path="../Network" }  # Aliased Dependency
)
```

---

## 🏗 Using the Build in Your Code
Stowage eliminates hardcoded paths. If a manifest has `Dependencies`, a `Paths.ps1` file is generated in that directory during the build.

**In your script:**
```powershell
# 1. Load the map
. "$PSScriptRoot\Paths.ps1"

# 2. Access your dependencies via the $Paths hashtable
. (Join-Path $Paths.Logger "Initialize.ps1")
$Config = Get-Content $Paths.'config.json'
```

---

## ⚙️ Execution
Run **Stowage.ps1** from the terminal:

### Standard Build
```powershell
.\Stowage.ps1 -ProjectPath "C:\Repo\MyApp" -Destination "C:\Builds"
```

### Inventory Check (Dry Run)
To see a full "Bill of Materials" and validate all paths without building:
```powershell
.\Stowage.ps1 -ProjectPath "C:\Repo\MyApp" -ListAvailable
```

---

## 🛡 Stability Guards
*   **Circularity Protection**: Detects and blocks infinite dependency loops.
*   **Security Scope**: Ensures `SubProjects` never point to folders outside the root project tree.
*   **Reserved Names**: Prevents dependencies from being named `Shared` or `Paths`.
*   **Atomic Validation**: If any dependency in the entire recursive tree is missing, the build stops before any files are modified.

---

## 📝 Best Practices
1.  **Explicit is Better**: Stowage will only pack what you explicitly list in your manifests.
2.  **Use Aliases**: If two sub-projects need different versions of a library named `Common`, alias them to `CommonV1` and `CommonV2`.
3.  **Static Assets**: If a folder doesn't have a manifest, Stowage treats it as a "Dead End" asset and copies it without recursing further.


## License
**MIT License**

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
