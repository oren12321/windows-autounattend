Import-Module Pester

Describe "Invoke-EnterPostInstall - Initialization Behavior" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\EnterPostInstall.ps1"
    }

    BeforeEach {
        # Fresh simulated HKCU state for each test
        $global:regHKCU = $null

        #
        # Mocks
        #
        Mock Write-Timestamped {
            param($Message)
            # no-op, we just want to assert calls
        }

        Mock Test-Path {
            param($Path)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                return ($global:regHKCU -ne $null)
            }
            return $false
        }

        Mock New-Item {
            param($Path, $Force)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                $global:regHKCU = @{}
            }
        }

        Mock Get-ItemProperty {
            param($Path, $ErrorAction)

            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                if ($global:regHKCU -is [hashtable]) {
                    if ($global:regHKCU.Count -eq 0) {
                        # Simulate "no state yet"
                        return $null
                    }
                    return [pscustomobject]$global:regHKCU
                }
                return $null
            }
        }

        Mock New-ItemProperty {
            param($Path, $Name, $Value, $PropertyType, $Force)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                if (-not $global:regHKCU) {
                    $global:regHKCU = @{}
                }
                $global:regHKCU[$Name] = $Value
            }
        }
    }

    It "creates the HKCU key when it does not exist" {
        $global:regHKCU = $null

        Invoke-EnterPostInstall

        Assert-MockCalled New-Item -Times 1 -ParameterFilter {
            $Path -eq 'HKCU:\Software\MyCompany\PostInstall'
        }
    }

    It "does not recreate the HKCU key when it already exists" {
        $global:regHKCU = @{}

        Invoke-EnterPostInstall

        Assert-MockCalled New-Item -Times 0
    }

    It "returns immediately when state is already initialized" {
        $global:regHKCU = @{
            SetupComplete   = 1
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        Invoke-EnterPostInstall

        Assert-MockCalled New-ItemProperty -Times 0
    }

    It "initializes state when HKCU exists but has no values" {
        $global:regHKCU = @{}

        Invoke-EnterPostInstall

        $global:regHKCU["SetupComplete"]   | Should -Be 1
        $global:regHKCU["SetupCycle"]      | Should -Be 1
        $global:regHKCU["ActionRequired"]  | Should -Be 1
        $global:regHKCU["ActionCompleted"] | Should -Be 0
    }

    It "initializes state when HKCU key is newly created" {
        $global:regHKCU = $null

        Invoke-EnterPostInstall

        $global:regHKCU["SetupComplete"]   | Should -Be 1
        $global:regHKCU["SetupCycle"]      | Should -Be 1
        $global:regHKCU["ActionRequired"]  | Should -Be 1
        $global:regHKCU["ActionCompleted"] | Should -Be 0
    }

    It "logs that state already exists when initialized" {
        $global:regHKCU = @{
            SetupComplete   = 1
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        Invoke-EnterPostInstall

        Assert-MockCalled Write-Timestamped -Times 1 -ParameterFilter {
            $Message -like "*State already initialized*"
        }
    }

    It "logs initialization when creating new state" {
        $global:regHKCU = @{}

        Invoke-EnterPostInstall

        Assert-MockCalled Write-Timestamped -Times 1 -ParameterFilter {
            $Message -like "*Initializing per-user post-install state*"
        }
    }
}