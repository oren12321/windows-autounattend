BeforeAll {
    . "$PSScriptRoot\..\Generate-XmlSections.ps1"
}

Describe "Generate-XmlSections" {

    It "Generates Specialize XML with bootstrap script" {
        $xml = Generate-XmlSections -WorkspacePath "C:\Workspace" `
                                    -SpecializeScriptPath "C:\Specialize.ps1" `
                                    -FirstLogonScriptPath "C:\FL.ps1" `

        $xml.SpecializeXml | Should -Match "C:\\Specialize.ps1"
    }

    It "Generates FirstLogonCommands XML" {
        $xml = Generate-XmlSections -WorkspacePath "C:\Workspace" `
                                    -SpecializeScriptPath "C:\Specialize.ps1" `
                                    -FirstLogonScriptPath "C:\FL.ps1" `

        $xml.FirstLogonXml | Should -Match "C:\\FL.ps1"
    }

    It "Generates workspace stub" {
        $xml = Generate-XmlSections -WorkspacePath "C:\Workspace" `
                                    -SpecializeScriptPath "C:\Specialize.ps1" `
                                    -FirstLogonScriptPath "C:\FL.ps1" `

        $xml.WorkspacePath | Should -eq "C:\Workspace"
    }
}
