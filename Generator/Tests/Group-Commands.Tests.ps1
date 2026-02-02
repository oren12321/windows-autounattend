BeforeAll {
    . "$PSScriptRoot\..\Group-Commands.ps1"
}

Describe "Group-Commands" {

    It "Groups commands by Pass" {
        $normalized = @(
            @{ Project="A"; Pass="Specialize";  Order=2; Command="cmd1" },
            @{ Project="A"; Pass="FirstLogon";  Order=1; Command="cmd2" },
            @{ Project="B"; Pass="ActiveSetup"; Order=3; Command="cmd3" }
        )

        $result = Group-Commands -NormalizedCommands $normalized
        
        $result.Specialize.Count  | Should -Be 1
        $result.FirstLogon.Count  | Should -Be 1
        $result.ActiveSetup.Count | Should -Be 1
    }

    It "Sorts commands within each group by Order" {
        $normalized = @(
            @{ Project="A"; Pass="Specialize"; Order=5; Command="cmd5" },
            @{ Project="A"; Pass="Specialize"; Order=1; Command="cmd1" },
            @{ Project="A"; Pass="Specialize"; Order=3; Command="cmd3" }
        )

        $result = Group-Commands -NormalizedCommands $normalized

        $result.Specialize[0].Order | Should -Be 1
        $result.Specialize[1].Order | Should -Be 3
        $result.Specialize[2].Order | Should -Be 5
    }

    It "Returns empty arrays when no commands exist for a pass" {
        $normalized = @(
            @{ Project="A"; Pass="Specialize"; Order=1; Command="cmd1" }
        )

        $result = Group-Commands -NormalizedCommands $normalized

        $result.FirstLogon.Count  | Should -Be 0
        $result.ActiveSetup.Count | Should -Be 0
    }

    It "Handles an empty input array" {
        $result = Group-Commands -NormalizedCommands @()

        $result.Specialize.Count  | Should -Be 0
        $result.FirstLogon.Count  | Should -Be 0
        $result.ActiveSetup.Count | Should -Be 0
    }
}
