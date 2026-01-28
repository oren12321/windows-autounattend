# Pester 5 tests for Utils/Logging.ps1

BeforeAll {
    # Resolve module root relative to this test file
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent

    # Import the function under test
    . "$ModuleRoot\PostInstall\Utils\Logging.ps1"
}

Describe "Write-Timestamped" {

    Context "General behavior" {

        It "Does not throw when called with a normal message" {
            { Write-Timestamped -Message "Hello" } | Should -Not -Throw
        }

        It "Outputs a string to the pipeline" {
            Mock Get-Date { "2024-01-01 12:00:00" }

            $result = Write-Timestamped -Message "Test" 6>&1

            $result.MessageData | Should -BeOfType "System.String"
        }
    }

    Context "Timestamp formatting" {

        It "Uses the correct timestamp format" {
            Mock Get-Date { "2024-05-10 07:08:09" }

            $result = Write-Timestamped -Message "Message" 6>&1

            $result | Should -Be "2024-05-10 07:08:09 | Message"
        }
    }

    Context "Message handling" {

        It "Handles an empty string message" {
            Mock Get-Date { "2024-01-01 00:00:00" }

            $result = Write-Timestamped -Message "" 6>&1

            $result | Should -Be "2024-01-01 00:00:00 | "
        }

        It "Handles a null message" {
            Mock Get-Date { "2024-01-01 00:00:00" }

            $result = Write-Timestamped -Message $null 6>&1

            $result | Should -Be "2024-01-01 00:00:00 | "
        }
    }

    Context "Parameter validation" {

        It "Accepts a string parameter" {
            $param = (Get-Command Write-Timestamped).Parameters["Message"]
            $param.ParameterType | Should -Be ([string])
        }
    }
}

Describe "Format-Line" {

    It "General format" {
        $result = Format-Line -Level "Info" -Message "Some text ..."
        $result | Should -Match 'INFO[ ]*\| <prompt>[ ]*\| (<interactive>|.+\.ps1:[0-9]+)[ ]*\| Some text ...'
    }
}