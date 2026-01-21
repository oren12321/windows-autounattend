# Tests/PostInstallAction.Tests.ps1
Import-Module Pester

Describe 'PostInstallAction.ps1' {
    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'

    BeforeEach {
        Mock Test-Path { $true }
        Mock Start-Process {}
        Mock Set-ItemProperty {}
        Mock Get-ItemProperty {
            [pscustomobject]@{
                ActionRequired  = 1
                ActionCompleted = 0
            }
        }
        
        #
        # Load scripts AFTER mocks so functions bind to mocks
        #
        $here = Split-Path -Parent $PSCommandPath
        $scriptRoot = Split-Path -Parent $here
        
        . (Join-Path $scriptRoot "PostInstallAction.ps1")
    }

    It 'shows toast and updates flags when action required' {
        Invoke-PostInstallAction

        Assert-MockCalled Start-Process -Times 1
        Assert-MockCalled Set-ItemProperty -Times 2
    }

    It 'does nothing when action not required' {
        Mock Get-ItemProperty {
            [pscustomobject]@{
                ActionRequired  = 0
                ActionCompleted = 0
            }
        }

        Invoke-PostInstallAction
        
        Assert-MockCalled Start-Process -Times 0
        Assert-MockCalled Set-ItemProperty -Times 0
    }
}
