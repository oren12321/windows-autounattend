BeforeAll {
    # Resolve project root
    # Resolve module root relative to this test file
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent

    # Import the function under test
    . "$ModuleRoot\PostInstall\Monitor\Load-PostInstallComponents.ps1"
}

Describe "Load-PostInstallComponents" {

    BeforeEach {
        # Create a temp directory for component files
        $script:TempDir = Join-Path $env:TEMP ("PesterComponents_" + [guid]::NewGuid())
        
        New-Item -ItemType Directory -Path $TempDir | Out-Null
    }

    AfterEach {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Directory validation" {

        It "Returns empty array when directory does not exist" {
            $result = Load-PostInstallComponents -ComponentsDirectory "Z:\DefinitelyNotReal"
            $result | Should -BeNullOrEmpty
        }

        It "Returns empty array when directory contains no .ps1 files" {
            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Component file loading" {

        It "Skips file that throws during dot-sourcing" {
            $badFile = Join-Path $TempDir "Bad.ps1"
            @"
throw 'Boom'
"@ | Set-Content $badFile

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir
            $result | Should -BeNullOrEmpty
        }

        It "Skips file that does not define `$Component" {
            $file = Join-Path $TempDir "NoComponent.ps1"
            @"
# no component here
"@ | Set-Content $file

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir
            $result | Should -BeNullOrEmpty
        }

        It "Skips component missing required scriptblocks" {
            $file = Join-Path $TempDir "MissingBlocks.ps1"
            @"
`$Component = [pscustomobject]@{
    Name = 'Test'
    StartCondition = { `$true }
    # Missing Action + StopCondition
}
"@ | Set-Content $file

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir
            $result | Should -BeNullOrEmpty
        }

        It "Loads a valid component successfully" {
            $file = Join-Path $TempDir "Valid.ps1"
            @"
`$Component = [pscustomobject]@{
    Name = 'Valid'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
}
"@ | Set-Content $file

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir
            
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be "Valid"
        }

        It "Loads multiple valid components" {
            $file1 = Join-Path $TempDir "A.ps1"
            $file2 = Join-Path $TempDir "B.ps1"

            @"
`$Component = [pscustomobject]@{
    Name = 'A'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
}
"@ | Set-Content $file1

            @"
`$Component = [pscustomobject]@{
    Name = 'B'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
}
"@ | Set-Content $file2

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir

            $result.Count | Should -Be 2
            $result.Name | Should -Contain "A"
            $result.Name | Should -Contain "B"
        }

        It "Ensures `$Component is cleared between files" {
            # First file defines a component
            $file1 = Join-Path $TempDir "First.ps1"
            @"
`$Component = [pscustomobject]@{
    Name = 'First'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
}
"@ | Set-Content $file1

            # Second file does NOT define $Component
            $file2 = Join-Path $TempDir "Second.ps1"
            @"
# no component here
"@ | Set-Content $file2

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir

            # Only the first component should load
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be "First"
        }
    }
}