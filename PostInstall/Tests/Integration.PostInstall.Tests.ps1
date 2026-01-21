Import-Module Pester

Describe 'Post-install integration' {

    BeforeEach {

        #
        # Reset fake registry
        #
        $script:regHKCU = $null
        $script:regHKLM = @{ TargetCycle = 1 }

        #
        # Helper: preserve key casing when writing registry values
        #
        function Set-RegValue([string]$Name, $Value) {
            if ($script:regHKCU -eq $null) {
                $script:regHKCU = [ordered]@{}
            }

            # Remove existing key (case-insensitive)
            foreach ($key in @($script:regHKCU.Keys)) {
                if ($key -ieq $Name) {
                    $script:regHKCU.Remove($key)
                }
            }

            # Add with correct casing
            $script:regHKCU[$Name] = $Value
        }

        #
        # Mocks
        #
        Mock Test-Path {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return $script:regHKCU -ne $null }
                'HKLM:\Software\MyCompany\PostInstall' { return $true }
                default { return $true }   # allow action script to "exist"
            }
        }

        Mock New-Item {
            param($Path)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                $script:regHKCU = [ordered]@{}
            }
        }

        Mock New-ItemProperty {
            param($Path, $Name, $Value)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                Set-RegValue $Name $Value
            }
        }

        Mock Get-ItemProperty {
            param($Path)

            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {

                if ($script:regHKCU -eq $null) { return $null }
                if ($script:regHKCU.Count -eq 0) { return $null }

                return [pscustomobject]$script:regHKCU
            }

            if ($Path -eq 'HKLM:\Software\MyCompany\PostInstall') {
                return [pscustomobject]$script:regHKLM
            }
        }

        Mock Set-ItemProperty {
            param($Path, $Name, $Value)

            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                Set-RegValue $Name $Value
            }
            elseif ($Path -eq 'HKLM:\Software\MyCompany\PostInstall') {
                $script:regHKLM[$Name] = $Value
            }
        }

        Mock Start-Process {}
        Mock Start-Sleep {}

        #
        # Load scripts AFTER mocks so functions bind to mocks
        #
        $here = Split-Path -Parent $PSCommandPath
        $scriptRoot = Split-Path -Parent $here

        . (Join-Path $scriptRoot "EnterPostInstall.ps1")
        . (Join-Path $scriptRoot "PostInstallMonitor.ps1")
        . (Join-Path $scriptRoot "PostInstallAction.ps1")
    }

    It 'runs full flow: Enter -> Monitor -> Action -> flags updated' {

        Invoke-EnterPostInstall
        Invoke-PostInstallMonitor

        $script:regHKCU.SetupComplete   | Should -Be 1
        $script:regHKCU.SetupCycle      | Should -Be 1
        $script:regHKCU.ActionRequired  | Should -Be 0
        $script:regHKCU.ActionCompleted | Should -Be 1
    }

    It 'enforces new cycle when TargetCycle bumped' {

        Invoke-EnterPostInstall

        $script:regHKLM.TargetCycle     = 2
        $script:regHKCU.ActionRequired  = 0
        $script:regHKCU.ActionCompleted = 1

        Invoke-PostInstallMonitor

        $script:regHKCU.SetupCycle      | Should -Be 2
        $script:regHKCU.ActionRequired  | Should -Be 0
        $script:regHKCU.ActionCompleted | Should -Be 1
    }
}