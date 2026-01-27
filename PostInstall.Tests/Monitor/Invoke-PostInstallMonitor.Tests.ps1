BeforeAll {
    # Resolve project root
    # Resolve module root relative to this test file
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent

    # Import the function under test
    . "$ModuleRoot\PostInstall\Monitor\Invoke-PostInstallMonitor.ps1"
}

Describe "Get-CurrentLogonId" {

    BeforeEach {
        Mock Get-CurrentWindowsIdentityName { "MYDOMAIN\TestUser" }
        Mock Get-LogonSessions { @() }
    }

    It "returns the LogonId of the session matching the current user" {

        # Mock the CIM call used by Get-CurrentLogonId
        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Name="TestUser",Domain="MYDOMAIN"'
                    Dependent  = 'Win32_LogonSession.LogonId="1001"'
                }
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Name="User",Domain="OTHER"'
                    Dependent  = 'Win32_LogonSession.LogonId="2002"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be 1001
    }


    It "returns the first matching session when multiple sessions belong to the same user" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Name="TestUser",Domain="MYDOMAIN"'
                    Dependent  = 'Win32_LogonSession.LogonId="3003"'
                }
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Name="TestUser",Domain="MYDOMAIN"'
                    Dependent  = 'Win32_LogonSession.LogonId="3004"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be 3003
    }

    It "ignores sessions that do not match the current user" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Name="SomeoneElse",Domain="OTHER"'
                    Dependent  = 'Win32_LogonSession.LogonId="4001"'
                }
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Name="SomeoneElse",Domain="OTHER"'
                    Dependent  = 'Win32_LogonSession.LogonId="4002"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be $null
    }

    It "returns null when no logon sessions exist" {

        Mock Get-LogonSessions { @() }

        $result = Get-CurrentLogonId
        $result | Should -Be $null
    }

    It "returns null when sessions exist but have no associated users" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{
                    Antecedent = ''
                    Dependent  = 'Win32_LogonSession.LogonId="5001"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be $null
    }

    It "returns null when regex does not match the Antecedent format" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{
                    Antecedent = 'INVALID_FORMAT'
                    Dependent  = 'Win32_LogonSession.LogonId="6001"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be $null
    }
}

Describe "Invoke-PostInstallMonitor" {

    BeforeEach {
        # Prevent real logging
        Mock Write-Timestamped { param($msg) }

        # Stable time
        Mock Get-Date { [datetime]'2020-01-01' }

        # Stable boot time
        Mock Get-CimInstance {
            [pscustomobject]@{ LastBootUpTime = [datetime]'2020-01-01' }
        }

        # Prevent real logon lookup
        Mock Get-CurrentLogonId { 123 }

        # Default: no registry keys exist (overridden per test when needed)
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKCU:*' }
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKLM:*' }

        # Registry mocks
        Mock Get-ItemProperty { }
        Mock New-Item { }
        Mock New-ItemProperty { }
        Mock Set-ItemProperty { }
    }

    # ------------------------------------------------------------
    It "Does not run component when StartCondition is false" {
        $comp = [pscustomobject]@{
            Name          = 'CompA'
            TargetCycle   = 1
            StartCondition = { param($ctx) $false }
            Action         = { throw "Should not run" }
            StopCondition  = { $true }
        }

        { Invoke-PostInstallMonitor -Components @($comp) } | Should -Not -Throw

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -eq "StartCondition not met or component already up-to-date."
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Runs component when StartCondition is true" {
        # HKCU exists so registry update block runs
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKCU:*' }

        $comp = [pscustomobject]@{
            Name          = 'CompB'
            TargetCycle   = 1
            StartCondition = { param($ctx) $true }
            Action         = { param($ctx) }      # no-op, just needs to run
            StopCondition  = { param($ctx) $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        # We know the "run" path executed if SetupCycle was written
        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'SetupCycle'
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Uses HKLM override when TargetCycle is higher" {
        # HKCU exists so per-user registry is updated
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKCU:*' }

        # HKLM exists and overrides TargetCycle
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKLM:*' }

        Mock Get-ItemProperty {
            [pscustomobject]@{ TargetCycle = 5 }
        } -ParameterFilter { $Path -like 'HKLM:*' }

        $comp = [pscustomobject]@{
            Name          = 'CompC'
            TargetCycle   = 1
            StartCondition = { param($ctx) $true }
            Action         = { }
            StopCondition  = { $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'SetupCycle' -and $Value -eq 5
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Handles exception during registry update" {
        # HKCU exists so registry update block runs
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKCU:*' }

        # Force exception inside registry update block
        Mock New-ItemProperty { throw "Registry failure" }

        $comp = [pscustomobject]@{
            Name          = 'CompD'
            TargetCycle   = 1
            StartCondition = { param($ctx) $true }
            Action         = { }
            StopCondition  = { $true }
        }

        { Invoke-PostInstallMonitor -Components @($comp) } | Should -Not -Throw

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "ERROR: Failed to update registry for component 'CompD'*"
        } -Times 1
    }
}