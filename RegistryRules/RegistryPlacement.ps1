function Test-RegistryPlacement {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('SYSTEM','DefaultUser','FirstUser','PerUser')]
        [string]$Scope
    )

    # Normalize
    $p = $Path.ToUpper()

    # ---------------------------------------------------------
    # STEP 1 — HKLM - SYSTEM only
    # ---------------------------------------------------------
    if ($p.StartsWith("HKLM:\")) {
        return ($Scope -eq 'SYSTEM')
    }

    # ---------------------------------------------------------
    # STEP 2 — HKCU Policy keys - SYSTEM (HKLM equivalent)
    # ---------------------------------------------------------
    if ($p -match '^HKCU:\\SOFTWARE\\POLICIES\\' -or
        $p -match '^HKCU:\\SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\POLICIES\\') {
        return ($Scope -eq 'SYSTEM')
    }

    # ---------------------------------------------------------
    # STEP 3 — Autorun / Logon hooks
    # ---------------------------------------------------------
    if ($p -match '^HKCU:\\SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\RUN' -or
        $p -match '^HKCU:\\SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\RUNONCE') {

        switch ($Scope) {
            'DefaultUser' { return $true }
            'PerUser'     { return $true }
            'FirstUser'   { return $true }
            default       { return $false }
        }
    }

    # ---------------------------------------------------------
    # STEP 4 — MRU / History / Cache keys - FirstUser only
    # ---------------------------------------------------------
    if ($p -match 'RECENTDOCS|RUNMRU|TYPEDPATHS|PIDLMRU|USERASSIST|HISTORY|CACHE') {
        return ($Scope -eq 'FirstUser')
    }

    # ---------------------------------------------------------
    # STEP 5 — First-user-only semantics
    # ---------------------------------------------------------
    if ($p -match '\\USERS\\.*\\' -or
        $p -match 'PROFILELIST\\S-1-5-21-' -or
        $p -match 'CONTENTDELIVERYMANAGER' -or
        $p -match 'EXPLORER\\FIRSTRUN') {

        return ($Scope -eq 'FirstUser')
    }

    # ---------------------------------------------------------
    # STEP 6 — Generic HKCU preferences - DefaultUser + PerUser
    # ---------------------------------------------------------
    if ($p.StartsWith("HKCU:\")) {
        return ($Scope -in @('DefaultUser','PerUser'))
    }

    # ---------------------------------------------------------
    # STEP 7 — Fallback - DefaultUser + PerUser
    # ---------------------------------------------------------
    return ($Scope -in @('DefaultUser','PerUser'))
}

function Get-EntriesForScope {
    param(
        $Entries,
        [ValidateSet('SYSTEM','DefaultUser','FirstUser','PerUser')]
        $Scope
    )

    $filtered = @(
        foreach ($entry in $Entries) {

            if (Test-RegistryPlacement -Path $entry.Path -Scope $Scope) {
                $entry
            }
        }
    )

    return ,$filtered
}

function Convert-EntriesToDefaultUserHive {
    param(
        [Parameter(Mandatory)]
        $Entries,

        [string]$MountPoint = 'Registry::HKEY_USERS\DefaultUser'
    )

    $converted = foreach ($entry in $Entries) {
        $clone = $entry.PSObject.Copy()

        if ($clone.Path -like 'HKCU:\*') {
            $clone.Path = $clone.Path -replace '^HKCU:', $MountPoint
        }

        $clone
    }

    return ,$converted
}
