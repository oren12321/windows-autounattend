Import-Module Pester

Describe 'Invoke-PostInstallMonitor' {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\Utils\PostInstallComponent.ps1"
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        $script:regHKCU = @{
            SetupComplete   = 1
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $script:regHKLM = @{
            TargetCycle = 1
        }

        Mock Test-Path {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return $script:regHKCU.Count -gt 0 }
                'HKLM:\Software\MyCompany\PostInstall' { return $true }
                default { return $true }
            }
        }

        Mock Get-ItemProperty {
            param($Path)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                return [pscustomobject]$script:regHKCU
            }
            elseif ($Path -eq 'HKLM:\Software\MyCompany\PostInstall') {
                return [pscustomobject]$script:regHKLM
            }
        }

        Mock Set-ItemProperty {
            param($Path, $Name, $Value)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                $script:regHKCU[$Name] = $Value
            }
            elseif ($Path -eq 'HKLM:\Software\MyCompany\PostInstall') {
                $script:regHKLM[$Name] = $Value
            }
        }

        Mock Start-Sleep {}
        Mock Invoke-PostInstallAction {}
    }

    It 'invokes default action when required' {
        Invoke-PostInstallMonitor
        Assert-MockCalled Invoke-PostInstallAction -Times 1
    }

    It 'uses injected component StartCondition/Action/StopCondition' {
        # Make default condition false (ActionRequired=0)
        $script:regHKCU.ActionRequired  = 0
        $script:regHKCU.ActionCompleted = 0

        $script:customRuns = 0

        $component = New-PostInstallComponent `
            -StartCondition {
                param($state)
                # Start when SetupComplete = 1
                $state.SetupComplete -eq 1
            } `
            -Action {
                param($state)
                $script:customRuns++
            } `
            -StopCondition {
                param($state)
                # Stop after first run by simulating completion
                $script:regHKCU.ActionCompleted = 1
                $true
            }

        Invoke-PostInstallMonitor -Component $component

        # Default action not called
        Assert-MockCalled Invoke-PostInstallAction -Times 0
        # Custom action called once
        $script:customRuns | Should -Be 1
        # Flags updated by StopCondition
        $script:regHKCU.ActionRequired  | Should -Be 0
        $script:regHKCU.ActionCompleted | Should -Be 1
    }
}