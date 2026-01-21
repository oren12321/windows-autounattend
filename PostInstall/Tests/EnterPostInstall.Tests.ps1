Import-Module Pester

Describe 'EnterPostInstall.ps1' {

    BeforeAll {
        . "$PSScriptRoot\..\EnterPostInstall.ps1"
        Get-Command Invoke-EnterPostInstall -ErrorAction SilentlyContinue | Write-Host
    }

    BeforeEach {
        Mock Test-Path { $false }
        Mock New-Item {}
        Mock Get-ItemProperty { $null }
        Mock New-ItemProperty {}
    }

    It 'creates HKCU key and initializes state when missing' {
        Invoke-EnterPostInstall

        Assert-MockCalled New-Item -Times 1
        Assert-MockCalled New-ItemProperty -Times 4
    }
}