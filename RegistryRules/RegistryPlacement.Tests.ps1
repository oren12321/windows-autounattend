# RegistryPlacement.Tests.ps1

BeforeAll {
    . "$PSScriptRoot\RegistryPlacement.ps1"
}

Describe "Test-RegistryPlacement - HKLM rules" {

    It "HKLM goes only to SYSTEM" {
        Test-RegistryPlacement -Path "HKLM:\Software\Test" -Scope SYSTEM     | Should -BeTrue
        Test-RegistryPlacement -Path "HKLM:\Software\Test" -Scope DefaultUser | Should -BeFalse
        Test-RegistryPlacement -Path "HKLM:\Software\Test" -Scope FirstUser   | Should -BeFalse
        Test-RegistryPlacement -Path "HKLM:\Software\Test" -Scope PerUser     | Should -BeFalse
    }
}

Describe "Test-RegistryPlacement - HKCU Policy rules" {

    It "HKCU policy keys go to SYSTEM only" {
        Test-RegistryPlacement -Path "HKCU:\Software\Policies\Test" -Scope SYSTEM | Should -BeTrue
        Test-RegistryPlacement -Path "HKCU:\Software\Policies\Test" -Scope DefaultUser | Should -BeFalse
    }
}

Describe "Test-RegistryPlacement - Autorun rules" {

    It "Autorun keys go to all user scopes except SYSTEM" {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\Test"

        Test-RegistryPlacement -Path $p -Scope DefaultUser | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope FirstUser   | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope PerUser     | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope SYSTEM      | Should -BeFalse
    }
}

Describe "Test-RegistryPlacement - MRU/history rules" {

    It "MRU keys go only to FirstUser" {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"

        Test-RegistryPlacement -Path $p -Scope FirstUser   | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope DefaultUser | Should -BeFalse
        Test-RegistryPlacement -Path $p -Scope PerUser     | Should -BeFalse
        Test-RegistryPlacement -Path $p -Scope SYSTEM      | Should -BeFalse
    }
}

Describe "Test-RegistryPlacement - First-run semantics" {

    It "FirstRun keys go only to FirstUser" {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FirstRun"

        Test-RegistryPlacement -Path $p -Scope FirstUser   | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope DefaultUser | Should -BeFalse
        Test-RegistryPlacement -Path $p -Scope PerUser     | Should -BeFalse
    }
}

Describe "Test-RegistryPlacement - Generic HKCU preferences" {

    It "Generic HKCU goes to DefaultUser + PerUser" {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

        Test-RegistryPlacement -Path $p -Scope DefaultUser | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope PerUser     | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope FirstUser   | Should -BeFalse
        Test-RegistryPlacement -Path $p -Scope SYSTEM      | Should -BeFalse
    }
}

Describe "Test-RegistryPlacement - Fallback" {

    It "Fallback HKCU goes to DefaultUser + PerUser" {
        $p = "HKCU:\Software\Vendor\App"

        Test-RegistryPlacement -Path $p -Scope DefaultUser | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope PerUser     | Should -BeTrue
        Test-RegistryPlacement -Path $p -Scope FirstUser   | Should -BeFalse
        Test-RegistryPlacement -Path $p -Scope SYSTEM      | Should -BeFalse
    }
}

Describe "Get-EntriesForScope" {

    It "Filters entries correctly" {
        $entries = @(
            @{ Path = "HKLM:\Software\Test"; Name="A" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\Test"; Name="B" },
            @{ Path = "HKCU:\Software\Vendor\App"; Name="C" }
        )
        
        $system = Get-EntriesForScope -Entries $entries -Scope SYSTEM
        $system.Count | Should -Be 1
        $system[0].Path | Should -Be "HKLM:\Software\Test"

        $defaultUser = Get-EntriesForScope -Entries $entries -Scope DefaultUser
        $defaultUser.Count | Should -Be 2
    }
}

Describe "Convert-EntriesToDefaultUserHive" {

    It "Rewrites HKCU paths correctly" {
        $entries = @(
            @{ Path = "HKCU:\Software\Test"; Name="A" },
            @{ Path = "HKLM:\Software\Test"; Name="B" }
        )

        $converted = Convert-EntriesToDefaultUserHive -Entries $entries -MountPoint "Registry::HKEY_USERS\DefaultUser"

        $converted[0].Path | Should -Be "Registry::HKEY_USERS\DefaultUser\Software\Test"
        $converted[1].Path | Should -Be "HKLM:\Software\Test"
    }
}