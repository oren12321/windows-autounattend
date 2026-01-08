BeforeAll {
    . "$PSScriptRoot\Apply-Registry.ps1"
    . "$PSScriptRoot\TestData.ps1"
}

Describe "Apply-RegistryEntry" {

    BeforeEach {
        Mock Test-Path { $false }
        Mock New-Item { }
        Mock Get-ItemProperty { }
        Mock Set-ItemProperty { }
        Mock New-ItemProperty { }
        Mock Write-Output { }
    }

    It "Creates a key when Operation=EnsureKey" {
        Apply-RegistryEntry -Path "HKCU:\Software\TestKey" -Operation EnsureKey

        Assert-MockCalled New-Item -Times 1
    }

    It "Sets a normal value when Operation=Set and value exists" {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { @{ TestValue = 1 } }

        Apply-RegistryEntry -Path "HKCU:\Software\TestKey" -Operation Set -Name TestValue -Type DWord -Value 123

        Assert-MockCalled Set-ItemProperty -Times 1
    }

    It "Creates a value when Operation=Set and value does not exist" {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { $null }

        Apply-RegistryEntry -Path "HKCU:\Software\TestKey" -Operation Set -Name TestValue -Type DWord -Value 123

        Assert-MockCalled New-ItemProperty -Times 1
    }

    It "Modifies a byte when Operation=SetByte" {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { @{ BinaryValue = [byte[]](0,0,0) } }

        Apply-RegistryEntry -Path "HKCU:\Software\TestKey" -Operation SetByte -Name BinaryValue -Offset 1 -ByteValue 0xFF

        Assert-MockCalled Set-ItemProperty -ParameterFilter {
            $Value[1] -eq 0xFF
        }
    }

    It "Modifies a bit when Operation=SetBit" {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { @{ BinaryValue = [byte[]](0,0,0) } }

        Apply-RegistryEntry -Path "HKCU:\Software\TestKey" -Operation SetBit -Name BinaryValue -Offset 0 -BitIndex 3 -BitValue 1

        Assert-MockCalled Set-ItemProperty -ParameterFilter {
            ($Value[0] -band 0x08) -eq 0x08
        }
    }
    
    It "Deletes a value when Operation=Delete and Name exists" {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { @{ ValueToDelete = 1 } }
        Mock Remove-ItemProperty { }
        Mock Write-Output { }

        Apply-RegistryEntry -Operation Delete -Path "HKCU:\Software\TestKey" -Name "ValueToDelete"

        Assert-MockCalled Remove-ItemProperty -Times 1
    }

    It "Does not fail when deleting a value that does not exist" {
        Mock Test-Path { return $true }
        Mock Get-ItemProperty { return $null }
        Mock Write-Output { }

        Apply-RegistryEntry -Operation Delete -Path "HKCU:\Software\TestKey" -Name "MissingValue"

        Assert-MockCalled Write-Output -Times 1
    }

    It "Deletes a key when Operation=Delete and Name is not provided" {
        Mock Test-Path { $true }
        Mock Remove-Item { }
        Mock Write-Output { }

        Apply-RegistryEntry -Operation Delete -Path "HKCU:\Software\KeyToDelete"

        Assert-MockCalled Remove-Item -Times 1
    }

    It "Does not fail when deleting a key that does not exist" {
        Mock Test-Path { return $false }
        Mock Write-Output { }

        Apply-RegistryEntry -Operation Delete -Path "HKCU:\Software\MissingKey"

        Assert-MockCalled Write-Output -Times 1
    }

    It "Delete should not fall through to other operations" {
        Mock Test-Path { return $false }
        Mock Write-Output { }

        Apply-RegistryEntry -Operation Delete -Path "HKCU:\Software\TestKey"

        Assert-MockCalled Write-Output -Times 1
    }

}

Describe "Apply-RegistryBatch" {

    BeforeEach {
        Mock Apply-RegistryEntry { }
    }

    It "Calls Apply-RegistryEntry for each item" {
        Apply-RegistryBatch -Items $TestRegistryEntries

        Assert-MockCalled Apply-RegistryEntry -Times $TestRegistryEntries.Count
    }
}