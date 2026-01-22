Import-Module Pester

Describe "PostInstallMonitor - Component Exception Handling" {

    BeforeEach {
        # Make Write-Timestamped visible to the script in a guaranteed way
        function global:Write-Timestamped {
            param($Message)
            Write-Output $Message
        }

        # You don't need to Mock Write-Timestamped here at all
        Mock Start-Sleep {}
        Mock Get-ItemProperty { @{ ActionRequired = 1; ActionCompleted = 0 } }
        Mock Set-ItemProperty {}

        $testDir = Join-Path $PSScriptRoot "..\Components"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null

        @"
throw 'Boom'
"@ | Set-Content (Join-Path $testDir "10-Throws.ps1")
    }

    AfterEach {
        Remove-Item -Recurse -Force (Join-Path $PSScriptRoot "..\Components") -ErrorAction SilentlyContinue
    }

    It "logs the exception and continues" {
        $output = & "$PSScriptRoot\..\PostInstallMonitor.ps1" -InTestContext *>&1

        $text = $output -join "`n"
        $text | Should -Match "Failed to load component"
    }
}
