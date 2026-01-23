Import-Module Pester

Describe "PostInstallMonitor - Default Component Fallback" {

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

        # Create Components folder but all invalid
        $testDir = Join-Path $PSScriptRoot "..\Components"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        @"
# Missing scriptblocks
`$Component = @{ Foo = 'bar' }
"@ | Set-Content (Join-Path $testDir "10-Bad.ps1")
    }

    AfterEach {
        Remove-Item -Recurse -Force (Join-Path $PSScriptRoot "..\Components") -ErrorAction SilentlyContinue
    }

    It "falls back to default component and logs a warning" {
        # Load script (defines functions)
        . "$PSScriptRoot\..\PostInstallMonitor.ps1"

        # Run script (executes top-level loader)
        $output = & "$PSScriptRoot\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match "WARNING: No valid components loaded"
    }
}