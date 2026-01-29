BeforeAll {
    # Resolve module root
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent

    # Import function under test
    . "$ModuleRoot\PostInstall\Monitor\Load-PostInstallComponents.ps1"
}

Describe "Load-PostInstallComponents" {

    BeforeEach {
        # Create temp directory for component files
        $script:TempDir = Join-Path $env:TEMP ("PesterComponents_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TempDir | Out-Null

        # Mock registry operations
        Mock Test-Path { $true }
        Mock New-Item { @{ Path = $Path } }
        Mock New-ItemProperty { @{ Name = $Name; Value = $Value } }
        Mock Set-ItemProperty { @{ Name = $Name; Value = $Value } }
        Mock Remove-Item { }
        Mock Get-ItemProperty { return $null }
    }

    AfterEach {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Directory validation" {

        It "Returns empty array when directory does not exist" {
            Mock Test-Path { $false }

            $result = Load-PostInstallComponents -ComponentsDirectory "Z:\DefinitelyNotReal"
            $result | Should -BeNullOrEmpty
        }

        It "Returns empty array when directory contains no .ps1 files" {
            Mock Get-ChildItem { @() }

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
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\Test'
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
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\Valid'
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
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\A'
}
"@ | Set-Content $file1

@"
`$Component = [pscustomobject]@{
    Name = 'B'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\B'
}
"@ | Set-Content $file2

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir

            $result.Count | Should -Be 2
            $result.Name | Should -Contain "A"
            $result.Name | Should -Contain "B"
        }

        It "Ensures `$Component is cleared between files" {
            $file1 = Join-Path $TempDir "First.ps1"
@"
`$Component = [pscustomobject]@{
    Name = 'First'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\First'
}
"@ | Set-Content $file1

            $file2 = Join-Path $TempDir "Second.ps1"
@"
# no component here
"@ | Set-Content $file2

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir

            $result.Count | Should -Be 1
            $result[0].Name | Should -Be "First"
        }
    }

    #
    # EXTENDED TESTS
    #

    Context "Registry behavior" {

        It "Creates component registry key" {
            Mock Test-Path { $false } -ParameterFilter { $Path -like 'HKCU:*' }
            
            $file = Join-Path $TempDir "Reg.ps1"
@"
`$Component = [pscustomobject]@{
    Name = 'Reg'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\Reg'
}
"@ | Set-Content $file

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir

            Assert-MockCalled New-Item -Times 1 -ParameterFilter { $Path -like "*Components\Reg" }
        }

        It "Creates index entry" {
            $file = Join-Path $TempDir "Idx.ps1"
@"
`$Component = [pscustomobject]@{
    Name = 'Idx'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\Idx'
}
"@ | Set-Content $file

            $result = Load-PostInstallComponents -ComponentsDirectory $TempDir

            Assert-MockCalled New-ItemProperty -Times 1 -ParameterFilter { $Name -eq "Idx_Path" }
        }

        It "Removes component registry key if index write fails" {
            Mock New-ItemProperty { throw "fail" }

            $file = Join-Path $TempDir "Fail.ps1"
@"
`$Component = [pscustomobject]@{
    Name = 'Fail'
    StartCondition = { `$true }
    Action         = { }
    StopCondition  = { `$true }
    RegistryPath   = 'HKCU:\Software\PostInstall\Components\Fail'
}
"@ | Set-Content $file

            Load-PostInstallComponents -ComponentsDirectory $TempDir | Out-Null

            Assert-MockCalled Remove-Item -Times 1 -ParameterFilter { $Path -like "*Components\Fail" }
        }
    }
}