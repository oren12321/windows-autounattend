BeforeAll {
    . "$PSScriptRoot\..\Assemble-Autounattend.ps1"
}

Describe "Assemble-Autounattend" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("AssembleTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        $Template = Join-Path $TestRoot "Template.xml"
        $Output   = Join-Path $TestRoot "autounattend.xml"

        @"
<root>
{{SPECIALIZE}}
{{FIRSTLOGON}}
{{ACTIVESETUP}}
{{EMBEDDEDZIP}}
</root>
"@ | Set-Content $Template

        $script:Template = $Template
        $script:Output   = $Output
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Throws if template does not exist" {
        { Assemble-Autounattend -TemplatePath "C:\Missing.xml" `
                                -OutputPath $Output `
                                -XmlSections @{} `
                                -EmbeddedZipXml "" 2>$null } | Should -Throw
    }

    It "Replaces all placeholders" {
        $sections = @{
            SpecializeXml  = "<S>1</S>"
            FirstLogonXml  = "<F>2</F>"
            ActiveSetupXml = "<A>3</A>"
        }

        $zipXml = "<Z>4</Z>"

        $xml = Assemble-Autounattend -TemplatePath $Template `
                                     -OutputPath $Output `
                                     -XmlSections $sections `
                                     -EmbeddedZipXml $zipXml

        $xml | Should -Match "<S>1</S>"
        $xml | Should -Match "<F>2</F>"
        $xml | Should -Match "<A>3</A>"
        $xml | Should -Match "<Z>4</Z>"
    }

    It "Writes the final XML to disk" {
        $sections = @{
            SpecializeXml  = "<S/>"
            FirstLogonXml  = "<F/>"
            ActiveSetupXml = "<A/>"
        }

        $zipXml = "<Z/>"

        Assemble-Autounattend -TemplatePath $Template `
                              -OutputPath $Output `
                              -XmlSections $sections `
                              -EmbeddedZipXml $zipXml

        Test-Path $Output | Should -Be $true
    }
}
