BeforeAll {
    . "$PSScriptRoot\..\Generate-XmlSections.ps1"
}

Describe "Generate-XmlSections" {

    It "Generates Specialize XML with bootstrap script" {
        $groups = @{
            Specialize  = @()
            FirstLogon  = @()
            ActiveSetup = @()
        }

        $xml = Generate-XmlSections -Groups $groups `
                                    -BootstrapScriptPath "C:\Boot.ps1" `
                                    -FirstLogonScriptPath "C:\FL.ps1" `
                                    -ActiveSetupScriptPath "C:\AS.ps1"

        $xml.SpecializeXml | Should -Match "C:\\Boot.ps1"
    }

    It "Generates FirstLogonCommands XML" {
        $groups = @{
            Specialize  = @()
            FirstLogon  = @()
            ActiveSetup = @()
        }

        $xml = Generate-XmlSections -Groups $groups `
                                    -BootstrapScriptPath "C:\Boot.ps1" `
                                    -FirstLogonScriptPath "C:\FL.ps1" `
                                    -ActiveSetupScriptPath "C:\AS.ps1"

        $xml.FirstLogonXml | Should -Match "C:\\FL.ps1"
    }

    It "Generates Active Setup registry entries" {
        $groups = @{
            Specialize = @()
            FirstLogon = @()
            ActiveSetup = @(
                @{ Project="ProjA"; Order=10; Command="cmd" }
            )
        }

        $xml = Generate-XmlSections -Groups $groups `
                                    -BootstrapScriptPath "C:\Boot.ps1" `
                                    -FirstLogonScriptPath "C:\FL.ps1" `
                                    -ActiveSetupScriptPath "C:\AS.ps1"

        $xml.ActiveSetupXml | Should -Match "ProjA_10"
        $xml.ActiveSetupXml | Should -Match "C:\\AS.ps1"
    }
}
