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

        # Default: registry paths exist unless overridden
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKCU:*' }
        Mock Test-Path { $true } -ParameterFilter { $Path -like 'HKLM:*' }

        # Registry mocks
        Mock Get-ItemProperty { }
        Mock New-Item { }
        Mock New-ItemProperty { }
        Mock Set-ItemProperty { }
    }

    # ------------------------------------------------------------
    It "Initializes TargetCycle=0 on first discovery" {
        Mock Get-ItemProperty { $true } -ParameterFilter { $Path -like 'HKCU:*' }
        Mock Get-ItemProperty { $false } -ParameterFilter { $Path -like 'HKCU:*' -and $Name -eq 'TargetCycle' }

        $comp = [pscustomobject]@{
            Name='InitA'
            Reset={ }
            StartCondition={ $false }
            Action={ }
            StopCondition={ $false }
        }
        
        Invoke-PostInstallMonitor -Components @($comp)
        
        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'TargetCycle' -and $Value -eq 0
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Skips component when SetupCycle >= TargetCycle" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 2; TargetCycle = 2 }
        } -ParameterFilter { $Path -like 'HKCU:*' }

        $comp = [pscustomobject]@{
            Name='SkipA'
            Reset={ }
            StartCondition={ throw "Should not run" }
            Action={ throw "Should not run" }
            StopCondition={ throw "Should not run" }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Already up do date*"
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Runs Reset before StartCondition" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }

        
        $script:order = @()

        $script:stopState = $false

        $comp = [pscustomobject]@{
            Name='OrderA'
            Reset={ $script:order += 'Reset' }
            StartCondition={ $script:order += 'Start'; $true }
            StopCondition={ $script:order += 'Stop'; $script:stopState }
            Action={ $script:order += 'Action'; $script:stopState = $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        $order | Should -Be @('Reset','Start','Stop','Action','Stop')
    }

    # ------------------------------------------------------------
    It "Does not run Action when StopCondition is true before Action" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        Mock Get-ItemProperty {
            $false
        } -ParameterFilter { $Path -like 'HKCU:*' -and $Name -eq 'SetupCycle' }
        
        $script:ran = $false

        $comp = [pscustomobject]@{
            Name='StopEarly'
            Reset={ }
            StartCondition={ $true }
            Action={ $script:ran = $true }
            StopCondition={ $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        $ran | Should -BeFalse

        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'SetupCycle'
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Runs Action when StartCondition true and StopCondition false" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $script:ran = $false

        $comp = [pscustomobject]@{
            Name='RunA'
            Reset={ }
            StartCondition={ $true }
            StopCondition={ $false }
            Action={ $script:ran = $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        $ran | Should -BeTrue
    }

    # ------------------------------------------------------------
    It "Updates SetupCycle after Action when StopCondition becomes true" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        Mock Get-ItemProperty {
            $false
        } -ParameterFilter { $Path -like 'HKCU:*' -and $Name -eq 'SetupCycle' }
        
        $script:stopState = $false

        $comp = [pscustomobject]@{
            Name='PostStop'
            Reset={ }
            StartCondition={ $true }
            StopCondition={ $script:stopState }
            Action={ $script:stopState = $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'SetupCycle'
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Persists context fields after Action" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $comp = [pscustomobject]@{
            Name='CtxA'
            Reset={ }
            StartCondition={ $true }
            StopCondition={ $false }
            Action={ }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled Set-ItemProperty -ParameterFilter {
            $Name -eq 'UserName'
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Loads LastRun from registry" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1; LastRun = ([datetime]'2019-01-01').ToFileTimeUtc() }
        } -ParameterFilter { $Path -like 'HKCU:*' }

        $script:received = $null

        $comp = [pscustomobject]@{
            Name='LastRunA'
            Reset={ }
            StartCondition={ param($ctx) $script:received = $ctx.LastRun; $false }
            Action={ }
            StopCondition={ $false }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        $received | Should -Be ([datetime]'2019-01-01')
    }

    # ------------------------------------------------------------
    It "Writes LastRun only when cycle completes" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        Mock Get-ItemProperty {
            $false
        } -ParameterFilter { $Path -like 'HKCU:*' -and $Name -eq 'LastRun' }
        
        $comp = [pscustomobject]@{
            Name='LastRunWrite'
            Reset={ }
            StartCondition={ $true }
            StopCondition={ $true }
            Action={ }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'LastRun'
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Uses HKLM override when higher" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ TargetCycle = 5 }
        } -ParameterFilter { $Path -like 'HKLM:*' }

        $comp = [pscustomobject]@{
            Name='OverrideA'
            Reset={ }
            StartCondition={ $true }
            StopCondition={ $true }
            Action={ }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled New-ItemProperty -ParameterFilter {
            $Name -eq 'SetupCycle' -and $Value -eq 5
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Handles exception in Reset gracefully" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $comp = [pscustomobject]@{
            Name='ErrReset'
            Reset={ throw "ResetFail" }
            StartCondition={ $false }
            StopCondition={ $false }
            Action={ }
        }

        { Invoke-PostInstallMonitor -Components @($comp) } | Should -Not -Throw

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Reset*ResetFail*"
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Handles exception in StartCondition gracefully" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $comp = [pscustomobject]@{
            Name='ErrStart'
            Reset={ }
            StartCondition={ throw "Boom" }
            StopCondition={ $false }
            Action={ }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*StartCondition*Boom*"
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Handles exception in Action but still evaluates StopCondition" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $script:stopCalled = $false

        $comp = [pscustomobject]@{
            Name='ErrAction'
            Reset={ }
            StartCondition={ $true }
            Action={ throw "ActionFail" }
            StopCondition={ $script:stopCalled = $true }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        $stopCalled | Should -BeTrue
    }

    # ------------------------------------------------------------
    It "Handles exception in StopCondition gracefully" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $comp = [pscustomobject]@{
            Name='ErrStop'
            Reset={ }
            StartCondition={ $true }
            Action={ }
            StopCondition={ throw "StopFail" }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*StopCondition*StopFail*"
        } -Times 1
    }

    # ------------------------------------------------------------
    It "Processes multiple components independently" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $script:ranA = $false
        $script:ranB = $false

        $compA = [pscustomobject]@{
            Name='A'
            Reset={ }
            StartCondition={ $true }
            Action={ $script:ranA = $true }
            StopCondition={ $false }
        }

        $compB = [pscustomobject]@{
            Name='B'
            Reset={ }
            StartCondition={ $true }
            Action={ $script:ranB = $true }
            StopCondition={ $false }
        }

        Invoke-PostInstallMonitor -Components @($compA, $compB)

        $ranA | Should -BeTrue
        $ranB | Should -BeTrue
    }

    # ------------------------------------------------------------
    It "Creates registry path when missing" {
        Mock Test-Path { $false } -ParameterFilter { $Path -like 'HKCU:*' }

        $comp = [pscustomobject]@{
            Name='RegCreate'
            Reset={ }
            StartCondition={ $false }
            Action={ }
            StopCondition={ $false }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        Assert-MockCalled New-Item -Times 1
    }

    # ------------------------------------------------------------
    It "Passes context object to component functions" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ SetupCycle = 0; TargetCycle = 1 }
        } -ParameterFilter { $Path -like 'HKCU:*' }
        
        $script:received = $null

        $comp = [pscustomobject]@{
            Name='CtxPass'
            Reset={ }
            StartCondition={ param($ctx) $script:received = $ctx; $false }
            Action={ }
            StopCondition={ $false }
        }

        Invoke-PostInstallMonitor -Components @($comp)

        $received | Should -Not -BeNullOrEmpty
        $received.PSObject.Properties.Name | Should -Contain 'ComponentRegistry'
    }
}