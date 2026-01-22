Import-Module Pester

Describe "PostInstallMonitor - Single Component.ps1" {

    BeforeAll {
            $here = Split-Path -Parent $PSCommandPath
            . "$here\..\PostInstallAction.ps1"
        }

    BeforeEach {
        # Replace Write-Timestamped with a stub that writes to output
        function global:Write-Timestamped {
            param($Message)
            Write-Output $Message
        }

        # Keep other mocks
        Mock Start-Sleep {}
        Mock Get-ItemProperty { @{ ActionRequired = 1; ActionCompleted = 0 } }
        Mock Set-ItemProperty {}
        Mock Invoke-PostInstallAction {}

        @"
`$Component = New-PostInstallComponent `
    -StartCondition { param(\$s) \$true } `
    -Action        { param(\$s) Write-Timestamped 'SingleAction' } `
    -StopCondition { param(\$s) \$true }
"@ | Set-Content (Join-Path $PSScriptRoot "..\Component.ps1")
    }

    AfterEach {
        Remove-Item (Join-Path $PSScriptRoot "..\Component.ps1") -Force -ErrorAction SilentlyContinue
    }

    It "loads and executes Component.ps1" {
        # Load script (defines functions)
        . "$PSScriptRoot\..\PostInstallMonitor.ps1"

        # Run script (executes top-level loader)
        $output = & "$PSScriptRoot\..\PostInstallMonitor.ps1" -InTestContext *>&1
        $text   = $output -join "`n"

        $text | Should -Match "SingleAction"
    }
}