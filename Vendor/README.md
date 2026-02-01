# PowerShell Diagnostic & Rotating Logging Framework

A high-traceability logging toolkit designed for complex automation and system deployments. This framework captures deep metadata from the [PowerShell CallStack](https://learn.microsoft.com) and provides automated file rotation to maintain system performance and disk health.

## Key Features

- **Deep Traceability**: Automatically captures the Calling Function, File Name, and Line Number for every log entry.
- **Automated Rotation**: Rotates log files based on a configurable `MaxSize` (e.g., 5MB) to prevent oversized files.
- **Retention Management**: Maintains a clean environment by purging old log segments based on a `MaxFiles` limit.
- **Universal Log Analysis**: Includes a streaming viewer that parses log files back into structured objects with wildcard filtering.
- **Metadata Alignment**: Uses fixed-width padding for log levels and source info, making logs easily readable in standard text editors or [CMTrace](https://learn.microsoft.com).
- **Stream Integration**: Leverages [PowerShell Information Streams](https://learn.microsoft.com) for structured output.

---

## Function Reference

### `Format-Line`
The core metadata engine. It inspects the current execution context to attribute the log message to its source.

| Component | Description |
| :--- | :--- |
| **Level** | Severity indicator (e.g., INFO, ERROR, WARN). |
| **Function** | The name of the function that initiated the log call. |
| **Source** | The specific script file and line number where the event occurred. |

### `Add-RotatingLog`
The storage and maintenance engine. Handles file I/O and lifecycle management.

- **MaxSize**: Triggers rotation once the active log file exceeds this byte count.
- **MaxFiles**: Maintains only the $N$ most recent log segments, deleting the oldest.

### `Write-Timestamped`
A utility wrapper that prepends a standard `yyyy-MM-dd HH:mm:ss` timestamp to messages. It is designed to wrap `Format-Line` output for high-detail chronological auditing.

### `Get-FormattedLog`
The analysis engine. It streams log files as structured objects. Use the `-Tail` switch for real-time monitoring and `-Filter` for universal wildcard searching across the entire log line (Time, Level, Source, or Message).

---

## Usage Examples

### Nested Metadata Logging
This example demonstrates how to combine metadata capture with timestamping.

```powershell
$LogPath = "C:\Logs\Deployment.log"

try {
    # Combine Timestamping with Metadata Formatting
    $LogEntry = Write-Timestamped -Message (Format-Line -Level "INFO" -Message "Initializing system audit...")
    $LogEntry | Add-RotatingLog -Path $LogPath -MaxSize 5MB -MaxFiles 5
}
catch {
    $ErrorEntry = Write-Timestamped -Message (Format-Line -Level "ERROR" -Message "Audit failed: $($_.Exception.Message)")
    $ErrorEntry | Add-RotatingLog -Path $LogPath -MaxSize 5MB -MaxFiles 5
}
```

### Real-Time Universal Monitoring
Watch for specific errors in real-time as they are written to the file, skipping previous history.

```powershell
# Filter by a specific script file and severity in a live tail
Get-FormattedLog -Path "C:\Logs\Deployment.log" -Filter "*Registry.ps1*" -Level "ERROR" -Tail -Last 0
```

---

## Technical Requirements
- **PowerShell 5.1+** or **PowerShell Core**.
- **File System Permissions**: The execution context must have Write/Modify permissions to the target log directory.

## License
**MIT License**

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
