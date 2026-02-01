# PowerShell Module Bundler & Packager

A robust recursive packaging utility for PowerShell projects. This tool resolves local dependencies defined in module manifests and bundles them into a standalone, deployable directory structure.

## 🚀 Purpose

In modular repository structures, scripts often depend on shared utility modules located in different directories. This script:
1.  **Resolves** relative dependencies within `.psd1` files.
2.  **Localized** those dependencies into a `Shared/` folder within the build artifact.
3.  **Prevents** circular references and validates versioning during the process.

## 🛠 Features

*   **Recursive Resolution:** Automatically traverses the entire dependency tree.
*   **Circular Dependency Detection:** Prevents infinite build loops with a stack-based tracking system.
*   **Path Validation:** Monitors the Windows 260-character path limit to prevent build failures.
*   **Inventory Mode:** Generates a report of all required modules and their versions without moving files.
*   **Smart Cleaning:** Automatically excludes `.git` metadata and previous build artifacts.

## 📋 Manifest Requirements

For a project to be bundled correctly, it must include a PowerShell Data File (`.psd1`) in the root folder following this structure:

```powershell
@{
    ModuleVersion = "1.4.2"
    # Relative paths to other module folders or scripts
    RequiredModules = @(
        "..\InternalTools\Logging"
        "..\Shared\FileSystemUtility"
    )
}
```

## 💻 Usage

### Standard Build
Bundles the target project and all nested dependencies into the default `.\Build` folder.
```powershell
.\Packager.ps1 -ProjectPath "C:\Repo\MainProject"
```

### Inventory Audit
To see a summary of all dependencies and their versions without performing a copy:
```powershell
.\Packager.ps1 -ProjectPath "C:\Repo\MainProject" -ListAvailable
```

### Custom Build Path
```powershell
.\Packager.ps1 -ProjectPath ".\MyModule" -Destination "D:\Deployments\Alpha" -Limit 500
```

## ⚙️ Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-ProjectPath` | String | *Required* | The root path of the project to be packaged. |
| `-Destination` | String | `.\Build` | The root directory where the bundled output will be saved. |
| `-Limit` | Integer | `260` | Maximum allowed character length for destination paths. |
| `-ListAvailable` | Switch | `False` | Performs a dry-run and prints a dependency inventory. |

## 📂 Output Structure

The bundler transforms your source into a localized hierarchy:
```text
Build/
└── MyProject/
    ├── MyProject.psd1
    ├── MyProject.ps1
    └── Shared/
        ├── Logging/
        └── FileSystemUtility/
```

---
*Created for automated CI/CD workflows and local project distribution.*

## License
**MIT License**

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
