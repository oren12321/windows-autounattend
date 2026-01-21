Import-Module Pester

Describe 'Invoke-PostInstallMonitor' {

    # Dot-source INSIDE Describe so functions load in execution scope
    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
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

    It 'invokes action when required' {
        Invoke-PostInstallMonitor
        Assert-MockCalled Invoke-PostInstallAction -Times 1
    }
}