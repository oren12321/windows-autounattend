BeforeAll {
    . "$PSScriptRoot\..\Validate-Manifest"
}

Describe "Validate-Manifest" {

    It "Accepts a valid manifest" {
        $manifest = @{
            Commands = @(
                @{
                    Pass    = "Specialize"
                    Order   = 10
                    Command = "powershell.exe -File .\Setup.ps1"
                }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" } | Should -Not -Throw
    }

    It "Throws if Commands key is missing" {
        $manifest = @{}

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Commands is not an array" {
        $manifest = @{ Commands = "not an array" }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if a command entry is not a hashtable" {
        $manifest = @{ Commands = @(123) }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Pass is missing" {
        $manifest = @{
            Commands = @(
                @{ Order = 1; Command = "cmd" }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Order is missing" {
        $manifest = @{
            Commands = @(
                @{ Pass = "Specialize"; Command = "cmd" }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Command is missing" {
        $manifest = @{
            Commands = @(
                @{ Pass = "Specialize"; Order = 1 }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Pass is invalid" {
        $manifest = @{
            Commands = @(
                @{ Pass = "InvalidPass"; Order = 1; Command = "cmd" }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Order is not integer" {
        $manifest = @{
            Commands = @(
                @{ Pass = "Specialize"; Order = "abc"; Command = "cmd" }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }

    It "Throws if Command is empty" {
        $manifest = @{
            Commands = @(
                @{ Pass = "Specialize"; Order = 1; Command = "" }
            )
        }

        { Validate-Manifest -Manifest $manifest -ProjectName "ProjA" 2>$null } | Should -Throw
    }
}
