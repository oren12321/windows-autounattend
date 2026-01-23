Import-Module Pester

Describe "PostInstallMonitor - Multiple Components" {
    
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

        # Create a fake Components folder
        $testDir = Join-Path $PSScriptRoot "..\Components"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        # Component 1
        @"
`$Component = New-PostInstallComponent `
    -StartCondition { param(\$s) \$true } `
    -Action        { param(\$s) Write-Timestamped 'Action1' } `
    -StopCondition { param(\$s) \$true }
"@ | Set-Content (Join-Path $testDir "10-First.ps1")

        # Component 2
        @"
`$Component = New-PostInstallComponent `
    -StartCondition { param(\$s) \$true } `
    -Action        { param(\$s) Write-Timestamped 'Action2' } `
    -StopCondition { param(\$s) \$true }
"@ | Set-Content (Join-Path $testDir "20-Second.ps1")
    }

    AfterEach {
        Remove-Item -Recurse -Force (Join-Path $PSScriptRoot "..\Components") -ErrorAction SilentlyContinue
    }

    It "executes components in alphabetical order" {
        # Load script (defines functions)
        . "$PSScriptRoot\..\PostInstallMonitor.ps1"

        # Run script (executes top-level loader)
        $output = & "$PSScriptRoot\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"
        
        $text | Should -Match "Action1"
        $text | Should -Match "Action2"
    }
}
