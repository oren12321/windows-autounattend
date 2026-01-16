function Apply-RegistryEntry {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Operation = "Set",
        [string]$Name,
        [ValidateSet("String","ExpandString","DWord","QWord","Binary","MultiString")]
        [string]$Type,
        $Value,
        [string]$Description = "",

        # For SetByte
        [int]$Offset,
        [byte]$ByteValue,

        # For SetBit
        [int]$BitIndex,
        [int]$BitValue
    )

    try {
        # Ensure key exists for operations that need it
        if ($Operation -notin @("Delete","EnsureKey") -and -not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Output "[SUCCESS] Created key | Path='$Path' Description='$Description'"
        }

        switch ($Operation) {

            "EnsureKey" {
                if (-not (Test-Path $Path)) {
                    New-Item -Path $Path -Force | Out-Null
                    Write-Output "[SUCCESS] Created key | Path='$Path' Description='$Description'"
                }
                return
            }

            "Set" {
                if (-not $Name) { throw "Operation 'Set' requires a Name" }

                $exists = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

                if ($exists) {
                    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
                }
                else {
                    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
                }

                Write-Output "[SUCCESS] $Description | Path='$Path' Name='$Name' Type='$Type' Value='$Value'"
            }

            "SetByte" {
                if (-not $Name) { throw "SetByte requires Name" }
                if ($Offset -lt 0) { throw "Offset must be >= 0" }

                $data = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name

                # If missing → create empty byte array and write it
                if (-not $data) {
                    $data = New-Object byte[] ($Offset + 1)
                    New-ItemProperty -Path $Path -Name $Name -Value $data -PropertyType Binary -Force | Out-Null
                }

                # If too small → expand
                if ($data.Length -le $Offset) {
                    $newData = New-Object byte[] ($Offset + 1)
                    $data.CopyTo($newData, 0)
                    $data = $newData
                }

                if ($data.Length -le $Offset) {
                    throw "Offset $Offset is outside data length $($data.Length)"
                }

                $data[$Offset] = $ByteValue

                Set-ItemProperty -Path $Path -Name $Name -Value $data -Force

                Write-Output "[SUCCESS] $Description | Modified byte $Offset of '$Path\$Name' to 0x{0:X2}" -f $ByteValue
            }

            "SetBit" {
                if (-not $Name) { throw "SetBit requires Name" }
                if ($Offset -lt 0) { throw "Offset must be >= 0" }
                if ($BitIndex -lt 0 -or $BitIndex -gt 7) { throw "BitIndex must be 0-7" }

                $data = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name

                # If missing → create empty byte array and write it
                if (-not $data) {
                    $data = New-Object byte[] ($Offset + 1)
                    New-ItemProperty -Path $Path -Name $Name -Value $data -PropertyType Binary -Force | Out-Null
                }

                # If too small → expand
                if ($data.Length -le $Offset) {
                    $newData = New-Object byte[] ($Offset + 1)
                    $data.CopyTo($newData, 0)
                    $data = $newData
                }

                if ($data.Length -le $Offset) {
                    throw "Offset $Offset is outside data length $($data.Length)"
                }

                $mask = 1 -shl $BitIndex

                if ($BitValue -eq 1) {
                    $data[$Offset] = $data[$Offset] -bor $mask
                }
                else {
                    $data[$Offset] = $data[$Offset] -band (-bnot $mask)
                }

                Set-ItemProperty -Path $Path -Name $Name -Value $data -Force

                Write-Output "[SUCCESS] $Description | Modified bit $BitIndex of byte $Offset in '$Path\$Name'"
            }
            
            "Delete" {
                if ($Name) {
                    if (Test-Path $Path) {
                        $exists = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue

                        if ($exists -ne $null) {
                            Remove-ItemProperty -Path $Path -Name $Name -Force
                            Write-Output "[SUCCESS] $Description | Deleted value '$Name' from '$Path'"
                        }
                        else {
                            Write-Output "[INFO] $Description | Value '$Name' does not exist at '$Path'"
                        }
                    }
                    else {
                        Write-Output "[INFO] $Description | Key '$Path' does not exist"
                    }
                }
                else {
                    if (Test-Path $Path) {
                        Remove-Item -Path $Path -Recurse -Force
                        Write-Output "[SUCCESS] $Description | Deleted key '$Path'"
                    }
                    else {
                        Write-Output "[INFO] $Description | Key '$Path' does not exist"
                    }
                }

                return
            }

            default {
                throw "Unknown operation '$Operation'"
            }
        }
    }
    catch {
        Write-Output "[ERROR] $Description | Failed at '$Path\$Name' : $($_.Exception.Message)"
    }
}

function Apply-RegistryBatch {
    param(
        [array]$Items
    )

    foreach ($item in $Items) {
        Apply-RegistryEntry @item
    }
}