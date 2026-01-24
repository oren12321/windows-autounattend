Import-Module Pester

Describe "Invoke-PostInstallAction - Behavior Coverage" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        #
        # Simulated HKCU registry state
        #
        $global:regHKCU = $null

        #
        # Mocks
        #
        Mock Write-Timestamped {
            param($Message)
        }

        Mock Get-ItemProperty {
            param($Path, $ErrorAction)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                if ($global:regHKCU) {
                    return [pscustomobject]$global:regHKCU
                }
                return $null
            }
        }

        Mock Test-Path {
            param($Path)
            # Only toast.ps1 path is relevant
            if ($Path -like "*Toast.ps1") {
                return $global:toastExists
            }
            return $false
        }

        Mock Start-Process {}

        Mock Set-ItemProperty {
            param($Path, $Name, $Value)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                $global:regHKCU[$Name] = $Value
            }
        }
    }

    It "exits when state does not exist" {
        $global:regHKCU = $null

        Invoke-PostInstallAction

        Assert-MockCalled Write-Timestamped -Times 1 -ParameterFilter {
            $Message -like "*State not found*"
        }

        Assert-MockCalled Set-ItemProperty -Times 0
        Assert-MockCalled Start-Process -Times 0
    }

    It "exits when action is not required (ActionRequired=0)" {
        $global:regHKCU = @{
            ActionRequired  = 0
            ActionCompleted = 0
        }

        Invoke-PostInstallAction

        Assert-MockCalled Write-Timestamped -Times 1 -ParameterFilter {
            $Message -like "*Action not required*"
        }

        Assert-MockCalled Start-Process -Times 0
        Assert-MockCalled Set-ItemProperty -Times 0
    }

    It "exits when action already completed (ActionCompleted=1)" {
        $global:regHKCU = @{
            ActionRequired  = 1
            ActionCompleted = 1
        }

        Invoke-PostInstallAction

        Assert-MockCalled Write-Timestamped -Times 1 -ParameterFilter {
            $Message -like "*Action not required*"
        }

        Assert-MockCalled Start-Process -Times 0
        Assert-MockCalled Set-ItemProperty -Times 0
    }

    It "runs toast script when it exists" {
        $global:regHKCU = @{
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:toastExists = $true

        Invoke-PostInstallAction

        Assert-MockCalled Start-Process -Times 1
        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Launching toast script*"
        }
    }

    It "logs missing toast script when it does not exist" {
        $global:regHKCU = @{
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:toastExists = $false

        Invoke-PostInstallAction

        Assert-MockCalled Start-Process -Times 0
        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Toast script not found*"
        }
    }

    It "updates registry flags after running action" {
        $global:regHKCU = @{
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:toastExists = $false

        Invoke-PostInstallAction

        $global:regHKCU["ActionCompleted"] | Should -Be 1
        $global:regHKCU["ActionRequired"]  | Should -Be 0

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Updating registry flags*"
        }
    }

    It "logs successful completion" {
        $global:regHKCU = @{
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:toastExists = $false

        Invoke-PostInstallAction

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Post-install action completed successfully*"
        }
    }
}