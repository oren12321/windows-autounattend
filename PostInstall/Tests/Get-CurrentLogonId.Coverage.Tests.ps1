Import-Module Pester

Describe "Get-CurrentLogonId - Behavior Coverage" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallMonitor.ps1"
    }

    BeforeEach {
        Mock Get-CurrentWindowsIdentityName { "MYDOMAIN\TestUser" }
        Mock Get-LogonSessions { @() }
        Mock Get-LoggedOnUsersForSession { @() }
    }

    It "returns the LogonId of the session matching the current user" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{ LogonId = 1001 }
                [pscustomobject]@{ LogonId = 2002 }
            )
        }

        Mock Get-LoggedOnUsersForSession -ParameterFilter { $Session.LogonId -eq 1001 } {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Domain="MYDOMAIN",Name="TestUser"'
                }
            )
        }

        Mock Get-LoggedOnUsersForSession -ParameterFilter { $Session.LogonId -eq 2002 } {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Domain="OTHER",Name="User"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be 1001
    }

    It "returns the first matching session when multiple sessions belong to the same user" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{ LogonId = 3003 }
                [pscustomobject]@{ LogonId = 3004 }
            )
        }

        Mock Get-LoggedOnUsersForSession {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Domain="MYDOMAIN",Name="TestUser"'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be 3003
    }

    It "ignores sessions that do not match the current user" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{ LogonId = 4001 }
                [pscustomobject]@{ LogonId = 4002 }
            )
        }

        Mock Get-LoggedOnUsersForSession {
            @(
                [pscustomobject]@{
                    Antecedent = 'Win32_Account.Domain="OTHER",Name="SomeoneElse"'
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
                [pscustomobject]@{ LogonId = 5001 }
            )
        }

        Mock Get-LoggedOnUsersForSession { @() }

        $result = Get-CurrentLogonId
        $result | Should -Be $null
    }

    It "returns null when regex does not match the Antecedent format" {

        Mock Get-LogonSessions {
            @(
                [pscustomobject]@{ LogonId = 6001 }
            )
        }

        Mock Get-LoggedOnUsersForSession {
            @(
                [pscustomobject]@{
                    Antecedent = 'INVALID_FORMAT'
                }
            )
        }

        $result = Get-CurrentLogonId
        $result | Should -Be $null
    }
}