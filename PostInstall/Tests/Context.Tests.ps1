Import-Module Pester

Describe "PostInstallMonitor - Context Object" {

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

        Mock Set-ItemProperty {}
        Mock Start-Sleep {}
        Mock Invoke-PostInstallAction {}
        
        # ⭐ Fix: mock LogonId provider
        Mock Get-CurrentLogonId { return 9999 }

        # ⭐ Fix: mock BootTime provider
        Mock Get-CimInstance { return @{ LastBootUpTime = (Get-Date).AddHours(-5) } }

    }

    It "passes a populated context object to components" {

        $script:receivedContext = $null

        $component = New-PostInstallComponent `
            -StartCondition {
                param($context)
                $script:receivedContext = $context
                $true
            } `
            -Action {
                param($context)
                $script:receivedContext = $context
            } `
            -StopCondition {
                param($context)
                $true
            } `
            -Name "TestComponent"

        Invoke-PostInstallMonitor -Component $component

        $script:receivedContext | Should -Not -BeNullOrEmpty
        $script:receivedContext.UserName      | Should -Not -BeNullOrEmpty
        $script:receivedContext.UserProfile   | Should -Not -BeNullOrEmpty
        $script:receivedContext.LocalAppData  | Should -Not -BeNullOrEmpty
        $script:receivedContext.ProgramData   | Should -Not -BeNullOrEmpty
        $script:receivedContext.LogonId       | Should -Not -BeNullOrEmpty
        $script:receivedContext.BootTime      | Should -Not -BeNullOrEmpty
        $script:receivedContext.Now           | Should -Not -BeNullOrEmpty

        $script:receivedContext.ComponentRegistry |
            Should -Be "HKCU:\Software\MyCompany\PostInstall\Components\TestComponent"
    }
}