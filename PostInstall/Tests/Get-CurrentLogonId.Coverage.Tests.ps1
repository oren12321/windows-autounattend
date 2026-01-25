Import-Module Pester

Describe "Get-CurrentLogonId - Behavior Coverage" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallMonitor.ps1"
    }

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