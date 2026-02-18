# Windows 11 Image Servicing Manual (DISM Slipstreaming)

This guide covers the process of downloading, integrating cumulative and Safe OS updates into a Windows 11 ISO, optimizing for a single edition (Pro), and rebuilding a UEFI-compliant bootable ISO.

## 1. Preparation & Downloads

### A. Windows 11 ISO
- Download the official ISO from the [Microsoft Software Download](https://www.microsoft.com) page.
- Use **7-Zip** to extract the ISO contents to: `C:\Win11ISO`

### B. Update Packages
1. Go to the [Microsoft Update Catalog](https://www.catalog.update.microsoft.com).
2. **Cumulative Update:** Search for `KB5077181`. 
   - Download the version for **x64-based systems**. 
   - Place the `.msu` file in `C:\Updates`.
3. **Safe OS Update:** Search for `KB5077180`. 
   - Download the **Safe OS Dynamic Update** for **x64-based systems**. 
   - Place the `.cab` file in `C:\Updates`.

### C. Environment Setup
- Install the [Windows ADK](https://learn.microsoft.com) (Check "Deployment Tools" during setup).
- Create working folders:
  - `C:\Mount` (For the main OS)
  - `C:\MountRE` (For the Recovery Environment)

## 2. Extraction & Identification
Open **Command Prompt (Admin)** and identify the index of the Pro edition:
```cmd
dism /Get-WimInfo /WimFile:C:\Win11ISO\sources\install.wim
```
*(Note the index number for "Windows 11 Pro", usually **6**).*

## 3. Image Servicing (DISM)

**Step A: Mount the Main Image**
```cmd
dism /Mount-Wim /WimFile:C:\Win11ISO\sources\install.wim /Index:6 /MountDir:C:\Mount
```

**Step B: Integrate Cumulative Update**
```cmd
dism /Image:C:\Mount /Add-Package /PackagePath:C:\Updates\windows11.0-kb5077181-x64.msu
```

**Step C: Update Recovery Environment (WinRE)**
1. Mount the internal WinRE image:
   ```cmd
   dism /Mount-Wim /WimFile:C:\Mount\Windows\System32\Recovery\winre.wim /Index:1 /MountDir:C:\MountRE
   ```
2. Add the Safe OS Update:
   ```cmd
   dism /Image:C:\MountRE /Add-Package /PackagePath:C:\Updates\windows11.0-kb5077180-x64.cab
   ```
3. Commit and Unmount WinRE:
   ```cmd
   dism /Unmount-Wim /MountDir:C:\MountRE /Commit
   ```

**Step D: Finalize OS Image**
```cmd
dism /Unmount-Wim /MountDir:C:\Mount /Commit
```

## 4. Optimization & Splitting
To keep only the Pro edition and stay under the 4GB FAT32 limit:

1. **Export Pro only:**
   ```cmd
   dism /Export-Image /SourceImageFile:C:\Win11ISO\sources\install.wim /SourceIndex:6 /DestinationImageFile:C:\Win11ISO\sources\install_pro.wim
   ```
2. **Replace original:**
   ```cmd
   del C:\Win11ISO\sources\install.wim
   ren C:\Win11ISO\sources\install_pro.wim install.wim
   ```
3. **Split for UEFI:**
   ```cmd
   dism /Split-Image /ImageFile:C:\Win11ISO\sources\install.wim /SWMFile:C:\Win11ISO\sources\install.swm /FileSize:4000
   del C:\Win11ISO\sources\install.wim
   ```

## 5. Create Bootable UEFI ISO
Open the **Deployment and Imaging Tools Environment** (from Start Menu) and run:
```cmd
oscdimg -m -o -u2 -udfver102 -L"WIN11_PRO_UPDATED" -bootdata:2#p0,e,b"C:\Win11ISO\boot\etfsboot.com"#pEF,e,b"C:\Win11ISO\efi\microsoft\boot\efisys.bin" "C:\Win11ISO" "C:\Updated_Win11.iso"
```

## 6. Verify ISO Integrity
To verify the final file hash (SHA256), run this in **PowerShell**:
```powershell
Get-FileHash "C:\Updated_Win11.iso" -Algorithm SHA256
```
