# Pester 5 tests for Utils/Logging.ps1

BeforeAll {
    # Import the function under test
    . "$PSScriptRoot\Logging.ps1"
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

            $result | Should -Be $null
        }

        It "Handles a null message" {
            Mock Get-Date { "2024-01-01 00:00:00" }

            $result = Write-Timestamped -Message $null 6>&1

            $result | Should -Be $null
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

Describe "Format-Line filtering behavior (real scripts)" {

    BeforeAll {
        # Dot-source the real Logging.ps1 into the test session
        . "$PSScriptRoot\Logging.ps1"

        # Create a unique temp directory under the user's real temp folder
        $script:TempDir = Join-Path $env:TEMP ("LoggingTests_" + [guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }

    AfterAll {
        if (Test-Path $TempDir) {
            Remove-Item -Recurse -Force $TempDir
        }
    }

    BeforeEach {
        # Cleanup filters in the current session scope
        Remove-Variable -Name LevelFilter -ErrorAction SilentlyContinue
        Get-Variable | Where-Object { $_.Name -like "*_LevelFilter" } | ForEach-Object {
            Remove-Variable -Name $_.Name -ErrorAction SilentlyContinue
        }
        
        #
        # Helper: create a real script file and dot-source it
        #
        function Invoke-TestScript {
            param(
                [string]$ScriptName,
                [string]$ScriptContent
            )

            $path = Join-Path $TempDir "$ScriptName.ps1"
            Set-Content -Path $path -Value $ScriptContent -Encoding UTF8

            # Dot-source the script so its variables and calls run in this scope
            $output = . $path
            return $output
        }
    }

    

    Context "Per-file filter exists" {

        It "Uses the per-file filter when defined" {
            $scriptContent = @'
$MyScript_LevelFilter = @("INFO")
Format-Line -Level "INFO" -Message "Hello"
Format-Line -Level "DEBUG" -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $nonNull = @($output | Where-Object { $_ -ne $null })
            $nonNull.Count | Should -Be 1
            $nonNull[0]    | Should -Match "INFO"
        }

        It "Empty per-file filter suppresses all logs" {
            $scriptContent = @'
$MyScript_LevelFilter = @()
Format-Line -Level "INFO" -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $output | Should -Be $null
        }
    }

    Context "Global filter fallback" {

        It "Uses global filter when per-file filter is missing" {
            $scriptContent = @'
$LevelFilter = @("ERROR")
Format-Line -Level "ERROR" -Message "Oops"
Format-Line -Level "INFO"  -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "OtherScript" -ScriptContent $scriptContent

            $nonNull = @($output | Where-Object { $_ -ne $null })
            $nonNull.Count | Should -Be 1
            $nonNull[0]    | Should -Match "ERROR"
        }
    }

    Context "No filter defined at all" {

        It "Prints all logs when no filter exists" {
            $scriptContent = @'
Format-Line -Level "INFO"  -Message "Hello"
Format-Line -Level "DEBUG" -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "AnyScript" -ScriptContent $scriptContent

            $output.Count | Should -Be 2
        }
    }

    Context "Per-file filter overrides global filter" {

        It "Per-file filter takes precedence" {
            $scriptContent = @'
$LevelFilter = @("INFO")
$MyScript_LevelFilter = @("ERROR")
Format-Line -Level "ERROR" -Message "Oops"
Format-Line -Level "INFO"  -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $nonNull = @($output | Where-Object { $_ -ne $null })
            $nonNull.Count | Should -Be 1
            $nonNull[0]    | Should -Match "ERROR"
        }
    }

    Context "Case-insensitivity" {

        It "Handles lowercase filter values" {
            $scriptContent = @'
$MyScript_LevelFilter = @("error")
Format-Line -Level "ERROR" -Message "Oops"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $output.Count | Should -Be 1
        }
    }

    Context "Malformed filter variables" {

        It "Null filter means print everything" {
            $scriptContent = @'
$MyScript_LevelFilter = $null
Format-Line -Level "DEBUG" -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $output.Count | Should -Be 1
        }

        It "Handles string filter value of existing level" {
            $scriptContent = @'
$MyScript_LevelFilter = "debug"
Format-Line -Level "DEBUG" -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $output.Count | Should -Be 1
        }
        
        It "Handles string filter value of non-existing level" {
            $scriptContent = @'
$MyScript_LevelFilter = "other debug"
Format-Line -Level "DEBUG" -Message "Hello"
'@

            $output = Invoke-TestScript -ScriptName "MyScript" -ScriptContent $scriptContent

            $output.Count | Should -Be 0
        }
    }
}
