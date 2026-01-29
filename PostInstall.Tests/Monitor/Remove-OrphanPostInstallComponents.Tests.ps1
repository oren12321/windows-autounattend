BeforeAll {
    # Resolve project root
    # Resolve module root relative to this test file
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent

    # Import the function under test
    . "$ModuleRoot\PostInstall\Monitor\Remove-OrphanPostInstallComponents.ps1"
    
    $script:indexPath = "HKCU:\Software\PostInstall\Index"
}

Describe "Remove-OrphanPostInstallComponents" {

    BeforeEach {
        # Reset mocks before each test
        Mock -CommandName Write-Timestamped
        Mock -CommandName Format-Line -MockWith { param($Level,$Message) "${Level}: $Message" }
        Mock -CommandName Test-Path
        Mock -CommandName Get-ItemProperty
        Mock -CommandName Remove-Item
        Mock -CommandName Remove-ItemProperty
    }

    Context "When index path does not exist" {

        It "Logs and exits early" {
            Mock Test-Path { $false }

            Remove-OrphanPostInstallComponents

            Should -Invoke Test-Path -Times 1
            Should -Invoke Write-Timestamped -Times 1
            Should -Invoke Get-ItemProperty -Times 0
        }
    }

    Context "When index exists but is empty" {

        It "Logs and exits early" {
            Mock Test-Path { $true }
            Mock Get-ItemProperty { $null }

            Remove-OrphanPostInstallComponents

            Should -Invoke Get-ItemProperty -Times 1
            Should -Invoke Write-Timestamped -Times 1
            Should -Invoke Remove-Item -Times 0
        }
    }

    Context "When index contains components" {

        

        BeforeEach {
            Mock Test-Path {
                param($Path)
                switch ($Path) {
                    $script:indexPath { $true }
                    default { $true } # default for component file existence tests
                }
            }
        }

        It "Skips properties not ending with _Path" {
            Mock Get-ItemProperty {
                [pscustomobject]@{
                    Irrelevant = "ignored"
                }
            }

            Remove-OrphanPostInstallComponents

            Should -Invoke Remove-Item -Times 0
            Should -Invoke Remove-ItemProperty -Times 0
        }

        It "Processes valid component paths correctly" {
            Mock Get-ItemProperty {
                [pscustomobject]@{
                    ToolA_Path = "C:\Valid\File.exe"
                }
            }

            Mock Test-Path {
                param($Path)
                if ($Path -eq "C:\Valid\File.exe") { $true } else { $true }
            }

            Remove-OrphanPostInstallComponents

            Should -Invoke Remove-Item -Times 0
            Should -Invoke Remove-ItemProperty -Times 0
        }

        It "Removes orphaned components and their registry keys" {

            Mock Get-ItemProperty {
                [pscustomobject]@{
                    ToolB_Path = "C:\Missing\File.exe"
                }
            }

            Mock Test-Path {
                param($Path)
                switch ($Path) {
                    "C:\Missing\File.exe" { $false }
                    "HKCU:\Software\PostInstall\Components\ToolB" { $true }
                    default { $true }
                }
            }
            
            Remove-OrphanPostInstallComponents
            
            Should -Invoke Remove-Item -Times 1 -ParameterFilter {
                $Path -eq "HKCU:\Software\PostInstall\Components\ToolB"
            }

            Should -Invoke Remove-ItemProperty -Times 1 -ParameterFilter {
                $Path -eq $script:indexPath -and $Name -eq "ToolB_Path"
            }
        }

        It "Handles orphaned components whose registry key does not exist" {

            Mock Get-ItemProperty {
                [pscustomobject]@{
                    ToolC_Path = "C:\Missing2\File.exe"
                }
            }

            Mock Test-Path {
                param($Path)
                switch ($Path) {
                    "C:\Missing2\File.exe" { $false }
                    "HKCU:\Software\PostInstall\Components\ToolC" { $false }
                    default { $true }
                }
            }

            Remove-OrphanPostInstallComponents

            Should -Invoke Remove-Item -Times 0 -ParameterFilter {
                $Path -eq "HKCU:\Software\PostInstall\Components\ToolC"
            }

            Should -Invoke Remove-ItemProperty -Times 1 -ParameterFilter {
                $Path -eq $script:indexPath -and $Name -eq "ToolC_Path"
            }
        }
    }
}