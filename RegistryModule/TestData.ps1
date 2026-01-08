$TestRegistryEntries = @(
    @{
        Operation   = "EnsureKey"
        Path        = "HKCU:\Software\TestKey"
        Description = "Ensure key exists"
    },

    @{
        Operation   = "Set"
        Path        = "HKCU:\Software\TestKey"
        Name        = "TestValue"
        Type        = "DWord"
        Value       = 123
        Description = "Set a normal value"
    },

    @{
        Operation   = "SetByte"
        Path        = "HKCU:\Software\TestKey"
        Name        = "BinaryValue"
        Offset      = 1
        ByteValue   = 0xFF
        Description = "Modify byte"
    },

    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Software\TestKey"
        Name        = "BinaryValue"
        Offset      = 0
        BitIndex    = 3
        BitValue    = 1
        Description = "Modify bit"
    },
    
    # Delete a value
    @{
        Operation   = "Delete"
        Path        = "HKCU:\Software\TestKey"
        Name        = "ValueToDelete"
        Description = "Delete a specific value"
    },

    # Delete a key
    @{
        Operation   = "Delete"
        Path        = "HKCU:\Software\KeyToDelete"
        Description = "Delete an entire key"
    }

)