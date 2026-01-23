Import-Module Pester

Describe "PostInstallMonitor - Per Component Registry" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\Utils\PostInstallComponent.ps1"
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        # Simulated global HKCU/HKLM state
        $regHKCU = @{
            SetupComplete   = 1
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $regHKLM = @{
            TargetCycle = 1
        }

        # Mocks
        Mock Test-Path {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return $true }
                'HKLM:\Software\MyCompany\PostInstall' { return $true }
                default { return $true }
            }
        }

        Mock Get-ItemProperty {
            param($Path)

            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                return [pscustomobject]$regHKCU
            }

            if ($Path -eq 'HKLM:\Software\MyCompany\PostInstall') {
                return [pscustomobject]$regHKLM
            }

            if ($Path -like 'HKCU:\Software\MyCompany\PostInstall\Components\*') {
                # Components may read their own registry; just return empty object
                return [pscustomobject]@{}
            }
        }

        Mock New-Item { } # we don't care about creation details here

        Mock Set-ItemProperty {
            param($Path, $Name, $Value)
        }

        Mock Start-Sleep {}
        Mock Invoke-PostInstallAction {}

        Mock Get-CurrentLogonId { 9999 }
        Mock Get-CimInstance { @{ LastBootUpTime = (Get-Date).AddHours(-5) } }
    }

    It "allows each component to write to its own registry path" {

        $componentA = New-PostInstallComponent `
            -StartCondition { param($c) $true } `
            -Action {
                param($c)
                Set-ItemProperty -Path $c.ComponentRegistry -Name "ValueA" -Value 123
            } `
            -StopCondition { param($c) $true } `
            -Name "CompA"

        $componentB = New-PostInstallComponent `
            -StartCondition { param($c) $true } `
            -Action {
                param($c)
                Set-ItemProperty -Path $c.ComponentRegistry -Name "ValueB" -Value 456
            } `
            -StopCondition { param($c) $true } `
            -Name "CompB"

        Invoke-PostInstallMonitor -Component @($componentA, $componentB)

        # CompA writes only ValueA=123 to its own path
        Assert-MockCalled Set-ItemProperty -Times 1 -ParameterFilter {
            $Path -eq 'HKCU:\Software\MyCompany\PostInstall\Components\CompA' -and
            $Name -eq 'ValueA' -and
            $Value -eq 123
        }

        # CompB writes only ValueB=456 to its own path
        Assert-MockCalled Set-ItemProperty -Times 1 -ParameterFilter {
            $Path -eq 'HKCU:\Software\MyCompany\PostInstall\Components\CompB' -and
            $Name -eq 'ValueB' -and
            $Value -eq 456
        }

        # No cross-contamination: CompA must not write ValueB
        Assert-MockCalled Set-ItemProperty -Times 0 -ParameterFilter {
            $Path -eq 'HKCU:\Software\MyCompany\PostInstall\Components\CompA' -and
            $Name -eq 'ValueB'
        }

        # No cross-contamination: CompB must not write ValueA
        Assert-MockCalled Set-ItemProperty -Times 0 -ParameterFilter {
            $Path -eq 'HKCU:\Software\MyCompany\PostInstall\Components\CompB' -and
            $Name -eq 'ValueA'
        }
    }
}