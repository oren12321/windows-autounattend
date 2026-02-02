BeforeAll {
    . "$PSScriptRoot\..\Normalize-Commands.ps1"
}

Describe "Normalize-Commands" {

    It "Flattens commands from multiple projects" {
        $projects = @(
            @{
                Name = "ProjA"
                Manifest = @{
                    Commands = @(
                        @{ Pass="Specialize"; Order=10; Command="cmdA1" },
                        @{ Pass="FirstLogon"; Order=5; Command="cmdA2" }
                    )
                }
            },
            @{
                Name = "ProjB"
                Manifest = @{
                    Commands = @(
                        @{ Pass="ActiveSetup"; Order=1; Command="cmdB1" }
                    )
                }
            }
        )

        $result = Normalize-Commands -Projects $projects

        $result.Count | Should -Be 3
        $result.Project | Should -Contain "ProjA"
        $result.Project | Should -Contain "ProjB"
        $result.Command | Should -Contain "cmdA1"
        $result.Command | Should -Contain "cmdA2"
        $result.Command | Should -Contain "cmdB1"
    }

    It "Throws if a project has no Commands key" {
        $projects = @(
            @{
                Name = "ProjA"
                Manifest = @{}
            }
        )

        { Normalize-Commands -Projects $projects 2>$null } | Should -Throw
    }

    It "Preserves Pass, Order, and Command values" {
        $projects = @(
            @{
                Name = "ProjA"
                Manifest = @{
                    Commands = @(
                        @{ Pass="Specialize"; Order=42; Command="run.ps1" }
                    )
                }
            }
        )

        $result = Normalize-Commands -Projects $projects

        $result[0].Pass    | Should -Be "Specialize"
        $result[0].Order   | Should -Be 42
        $result[0].Command | Should -Be "run.ps1"
    }
}
