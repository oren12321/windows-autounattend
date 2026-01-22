Import-Module Pester

Describe "PostInstallMonitor - Invalid Component Handling" {

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

        $testDir = Join-Path $PSScriptRoot "..\Components"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        # Invalid component (missing $Component)
        @"
Write-Output 'This file is invalid'
"@ | Set-Content (Join-Path $testDir "10-Invalid.ps1")
    }

    AfterEach {
        Remove-Item -Recurse -Force (Join-Path $PSScriptRoot "..\Components") -ErrorAction SilentlyContinue
    }

    It "logs an error and skips invalid component" {
        # Load script (defines functions)
        . "$PSScriptRoot\..\PostInstallMonitor.ps1"

        # Run script (executes top-level loader)
        $output = & "$PSScriptRoot\..\PostInstallMonitor.ps1" -InTestContext *>&1
        $text   = $output -join "`n"

        $text | Should -Match "did not define a `\`$Component"
    }
}