Import-Module Pester

Describe "Invoke-PostInstallMonitor - Initial Behavior Coverage" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\..\Utils\Output.ps1"
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        #
        # Simulated registry
        #
        $global:regHKCU = $null
        $global:regHKLM = $null

        #
        # Mocks
        #
        Mock Write-Timestamped {}

        Mock Test-Path {
            param($Path)

            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return ($global:regHKCU -ne $null) }
                'HKLM:\Software\MyCompany\PostInstall' { return ($global:regHKLM -ne $null) }
                default { return $false }
            }
        }

        Mock Get-ItemProperty {
            param($Path)

            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' {
                    if ($global:regHKCU) { return [pscustomobject]$global:regHKCU }
                    return $null
                }
                'HKLM:\Software\MyCompany\PostInstall' {
                    if ($global:regHKLM) { return [pscustomobject]$global:regHKLM }
                    return $null
                }
            }
        }

        # IMPORTANT: return $null so it doesn't leak a fake registry path
        Mock Set-ItemProperty {
            param($Path, $Name, $Value)
            if ($Path -eq 'HKCU:\Software\MyCompany\PostInstall') {
                if (-not $global:regHKCU) { $global:regHKCU = @{} }
                $global:regHKCU[$Name] = $Value
            }
            $null
        }

        Mock Start-Sleep {}
        Mock Get-CurrentLogonId { 1234 }
        Mock Get-CimInstance { [pscustomobject]@{ LastBootUpTime = (Get-Date).AddHours(-5) } }
        Mock Invoke-PostInstallAction {}
    }

    # ----------------------------------------------------------------------
    # HKCU WAIT LOOP
    # ----------------------------------------------------------------------

    It "waits until HKCU appears, then continues" {

        $global:regHKCU = $null
        $global:counter = 0

        # HKCU appears only after 3 checks
        Mock Test-Path -ParameterFilter { $Path -eq 'HKCU:\Software\MyCompany\PostInstall' } {
            $global:counter++
            if ($counter -ge 3) {
                $global:regHKCU = @{
                    SetupCycle      = 1
                    ActionRequired  = 1
                    ActionCompleted = 0
                }
                return $true
            }
            return $false
        }

        Invoke-PostInstallMonitor

        # 1. It actually waited (loop ran multiple times)
        $global:counter | Should -BeGreaterThan 1

        # 2. It did NOT timeout
        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -eq "HKCU key did not appear within timeout. Exiting."
        } -Times 0
    }


    It "exits when HKCU never appears within timeout" {

        $global:regHKCU = $null

        Mock Test-Path -ParameterFilter { $Path -eq 'HKCU:\Software\MyCompany\PostInstall' } { $false }

        Invoke-PostInstallMonitor

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -eq "HKCU key did not appear within timeout. Exiting."
        }
    }

    # ----------------------------------------------------------------------
    # STATE READ + TARGET CYCLE
    # ----------------------------------------------------------------------

    It "reads HKCU state and logs it" {

        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 0
            ActionCompleted = 0
        }

        Invoke-PostInstallMonitor

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -eq "State: SetupCycle=1, ActionRequired=0, ActionCompleted=0"
        }
    }

    It "uses default TargetCycle=1 when HKLM key missing" {

        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 0
            ActionCompleted = 0
        }

        $global:regHKLM = $null

        Invoke-PostInstallMonitor

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*TargetCycle = 1*"
        }
    }

    It "reads TargetCycle from HKLM when present" {

        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 0
            ActionCompleted = 0
        }

        $global:regHKLM = @{
            TargetCycle = 5
        }

        Invoke-PostInstallMonitor

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*TargetCycle = 5*"
        }
    }

    # ----------------------------------------------------------------------
    # CYCLE BUMPING
    # ----------------------------------------------------------------------

    It "bumps user cycle when behind TargetCycle" {

        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 0
            ActionCompleted = 1
        }

        $global:regHKLM = @{
            TargetCycle = 3
        }

        Invoke-PostInstallMonitor

        $global:regHKCU["SetupCycle"]      | Should -Be 3
        $global:regHKCU["ActionRequired"]  | Should -Be 1
        $global:regHKCU["ActionCompleted"] | Should -Be 0

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*SetupCycle (1) is behind TargetCycle (3)*"
        }
    }

    It "does not bump cycle when already equal or ahead" {

        $global:regHKCU = @{
            SetupCycle      = 5
            ActionRequired  = 0
            ActionCompleted = 0
        }

        $global:regHKLM = @{
            TargetCycle = 3
        }

        Invoke-PostInstallMonitor

        $global:regHKCU["SetupCycle"] | Should -Be 5

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -notlike "*behind TargetCycle*"
        }
    }
}

Describe "Invoke-PostInstallMonitor - Context Building" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        #
        # Simulated registry
        #
        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:regHKLM = $null

        #
        # Mocks
        #
        Mock Write-Timestamped {}

        Mock Test-Path {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return $true }
                'HKLM:\Software\MyCompany\PostInstall' { return ($global:regHKLM -ne $null) }
                default { return $false }
            }
        }

        Mock Get-ItemProperty {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return [pscustomobject]$global:regHKCU }
                'HKLM:\Software\MyCompany\PostInstall' { return [pscustomobject]$global:regHKLM }
            }
        }

        Mock Set-ItemProperty {}

        Mock Start-Sleep {}

        Mock Get-CurrentLogonId { 9999 }

        Mock Get-CimInstance {
            [pscustomobject]@{ LastBootUpTime = (Get-Date).AddHours(-10) }
        }

        Mock Invoke-PostInstallAction {}

        # Capture context passed into component scriptblocks
        $script:capturedContext = $null

        # Dummy component that captures context and prevents further logic
        $script:Component = New-PostInstallComponent `
            -StartCondition {
                param($ctx)
                $script:capturedContext = $ctx
                return $false   # avoid running action/stop
            } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }
    }

    It "builds a context object with expected fields" {

        Invoke-PostInstallMonitor -Component $script:Component

        $ctx = $script:capturedContext
        $ctx | Should -Not -Be $null

        $ctx.UserName     | Should -Be $env:USERNAME
        $ctx.UserProfile  | Should -Be $env:USERPROFILE
        $ctx.LocalAppData | Should -Be $env:LOCALAPPDATA
        $ctx.ProgramData  | Should -Be $env:ProgramData
    }

    It "sets LogonId from Get-CurrentLogonId" {

        Invoke-PostInstallMonitor -Component $script:Component

        $ctx = $script:capturedContext
        $ctx.LogonId | Should -Be 9999
    }

    It "sets BootTime from Win32_OperatingSystem" {

        Invoke-PostInstallMonitor -Component $script:Component

        $ctx = $script:capturedContext
        $ctx.BootTime | Should -BeOfType "datetime"
        $ctx.BootTime | Should -BeLessThan (Get-Date)
    }

    It "sets Now to a DateTime value" {

        Invoke-PostInstallMonitor -Component $script:Component

        $ctx = $script:capturedContext
        $ctx.Now | Should -BeOfType "datetime"
    }

    It "Log delegate writes messages through Write-Timestamped" {

        Invoke-PostInstallMonitor -Component $script:Component

        $ctx = $script:capturedContext

        $ctx.Log.Invoke("hello world")

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -eq "hello world"
        }
    }
}

Describe "Invoke-PostInstallMonitor - Component Normalization" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        #
        # Simulated registry
        #
        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:regHKLM = $null

        #
        # Mocks
        #
        Mock Write-Timestamped {}
        Mock Start-Sleep {}

        Mock Test-Path {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return $true }
                'HKLM:\Software\MyCompany\PostInstall' { return ($global:regHKLM -ne $null) }
                default { return $false }
            }
        }

        Mock Get-ItemProperty {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return [pscustomobject]$global:regHKCU }
                'HKLM:\Software\MyCompany\PostInstall' { return [pscustomobject]$global:regHKLM }
            }
        }

        Mock Set-ItemProperty {}
        Mock Get-CurrentLogonId { 1111 }
        Mock Get-CimInstance { [pscustomobject]@{ LastBootUpTime = (Get-Date).AddHours(-2) } }
        Mock Invoke-PostInstallAction {}
    }

    # ----------------------------------------------------------------------
    # DEFAULT COMPONENT CREATION
    # ----------------------------------------------------------------------

    It "creates a default component when no Component parameter is provided" {

        $script:capturedComponent = $null

        # Capture the default component by intercepting StartCondition
        Mock New-PostInstallComponent {
            param($StartCondition, $Action, $StopCondition, $Name)
            $script:capturedComponent = [pscustomobject]@{
                StartCondition = $StartCondition
                Action         = $Action
                StopCondition  = $StopCondition
            }
            return $script:capturedComponent
        }

        Invoke-PostInstallMonitor

        $script:capturedComponent | Should -Not -Be $null
        $script:capturedComponent.StartCondition | Should -BeOfType "scriptblock"
        $script:capturedComponent.Action         | Should -BeOfType "scriptblock"
        $script:capturedComponent.StopCondition  | Should -BeOfType "scriptblock"
    }

    # ----------------------------------------------------------------------
    # SINGLE COMPONENT NORMALIZATION
    # ----------------------------------------------------------------------

    It "wraps a single component into an array" {

        $single = New-PostInstallComponent `
            -StartCondition { param($ctx) $false } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        $script:seenComponents = @()

        # Capture components passed to foreach loop
        Mock New-PostInstallComponent {}  # not used here

        Mock Write-Timestamped {}

        # Override StartCondition to capture context and stop execution
        $single.StartCondition = {
            param($ctx)
            $script:seenComponents += "hit"
            return $false
        }

        Invoke-PostInstallMonitor -Component $single

        $script:seenComponents.Count | Should -Be 1
    }

    # ----------------------------------------------------------------------
    # ARRAY COMPONENT NORMALIZATION
    # ----------------------------------------------------------------------

    It "uses array of components as-is" {

        $comp1 = New-PostInstallComponent `
            -StartCondition { param($ctx) $false } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        $comp2 = New-PostInstallComponent `
            -StartCondition { param($ctx) $false } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        $script:seen = @()

        $comp1.StartCondition = { param($ctx) $script:seen += "c1"; $false }
        $comp2.StartCondition = { param($ctx) $script:seen += "c2"; $false }

        Invoke-PostInstallMonitor -Component @($comp1, $comp2)

        $script:seen | Should -Contain "c1"
        $script:seen | Should -Contain "c2"
    }

    # ----------------------------------------------------------------------
    # DEFAULT COMPONENT BEHAVIOR
    # ----------------------------------------------------------------------

    It "default StartCondition returns true when ActionRequired=1 and ActionCompleted=0" {

        $script:capturedComponent = $null

        Mock New-PostInstallComponent {
            param($StartCondition, $Action, $StopCondition, $Name)
            $script:capturedComponent = [pscustomobject]@{
                StartCondition = $StartCondition
                Action         = $Action
                StopCondition  = $StopCondition
            }
            return $script:capturedComponent
        }

        Invoke-PostInstallMonitor

        $ctx = [pscustomobject]@{}
        $result = & $script:capturedComponent.StartCondition $ctx

        $result | Should -Be $true
    }

    It "default Action calls Invoke-PostInstallAction" {

        $script:capturedComponent = $null

        Mock New-PostInstallComponent {
            param($StartCondition, $Action, $StopCondition, $Name)
            $script:capturedComponent = [pscustomobject]@{
                StartCondition = { param($ctx) $true }
                Action         = $Action
                StopCondition  = { param($ctx) $false }
            }
            return $script:capturedComponent
        }

        Invoke-PostInstallMonitor

        Assert-MockCalled Invoke-PostInstallAction -Times 1
    }

    It "default StopCondition returns true when ActionCompleted=1" {

        $global:regHKCU["ActionCompleted"] = 1

        $script:capturedComponent = $null

        Mock New-PostInstallComponent {
            param($StartCondition, $Action, $StopCondition, $Name)
            $script:capturedComponent = [pscustomobject]@{
                StartCondition = { param($ctx) $true }
                Action         = { param($ctx) }
                StopCondition  = $StopCondition
            }
            return $script:capturedComponent
        }

        Invoke-PostInstallMonitor

        $ctx = [pscustomobject]@{}
        $result = & $script:capturedComponent.StopCondition $ctx

        $result | Should -Be $true
    }
}

Describe "Invoke-PostInstallMonitor - Component Execution Loop" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {
        #
        # Simulated registry
        #
        $global:regHKCU = @{
            SetupCycle      = 1
            ActionRequired  = 1
            ActionCompleted = 0
        }

        $global:regHKLM = $null

        #
        # Mocks
        #
        Mock Write-Timestamped {}
        Mock Start-Sleep {}

        Mock Test-Path {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return $true }
                'HKLM:\Software\MyCompany\PostInstall' { return ($global:regHKLM -ne $null) }
                default { return $false }
            }
        }

        Mock Get-ItemProperty {
            param($Path)
            switch ($Path) {
                'HKCU:\Software\MyCompany\PostInstall' { return [pscustomobject]$global:regHKCU }
                'HKLM:\Software\MyCompany\PostInstall' { return [pscustomobject]$global:regHKLM }
            }
        }

        Mock Set-ItemProperty {}
        Mock Get-CurrentLogonId { 2222 }
        Mock Get-CimInstance { [pscustomobject]@{ LastBootUpTime = (Get-Date).AddHours(-3) } }
        Mock Invoke-PostInstallAction {}
    }

    # ----------------------------------------------------------------------
    # START CONDITION FALSE → ACTION SKIPPED
    # ----------------------------------------------------------------------

    It "skips action when StartCondition returns false" {

        $comp = New-PostInstallComponent `
            -StartCondition { param($ctx) $false } `
            -Action { param($ctx) throw "Should not run" } `
            -StopCondition { param($ctx) $false }

        Invoke-PostInstallMonitor -Component $comp

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*StartCondition not met*"
        }
    }

    # ----------------------------------------------------------------------
    # START CONDITION TRUE → ACTION EXECUTED
    # ----------------------------------------------------------------------

    It "executes component action when StartCondition returns true" {

        $script:actionHit = $false

        $comp = New-PostInstallComponent `
            -StartCondition { param($ctx) $true } `
            -Action { param($ctx) $script:actionHit = $true } `
            -StopCondition { param($ctx) $false }

        Invoke-PostInstallMonitor -Component $comp

        $script:actionHit | Should -Be $true
    }

    # ----------------------------------------------------------------------
    # ACTION FALLBACK TO PostInstallAction.ps1
    # ----------------------------------------------------------------------

    It "falls back to Invoke-PostInstallAction when Action is null and script exists" {

        Mock Test-Path -ParameterFilter { $Path -like "*PostInstallAction.ps1" } { $true }

        $comp = [pscustomobject]@{
            Name           = "X"
            StartCondition = { param($ctx) $true }
            Action         = $null
            StopCondition  = { param($ctx) $false }
        }

        Invoke-PostInstallMonitor -Component $comp

        Assert-MockCalled Invoke-PostInstallAction -Times 1
    }

    It "logs missing action script when Action is null and script does not exist" {

        Mock Test-Path -ParameterFilter { $Path -like "*PostInstallAction.ps1" } { $false }

        $comp = [pscustomobject]@{
            Name           = "X"
            StartCondition = { param($ctx) $true }
            Action         = $null
            StopCondition  = { param($ctx) $false }
        }

        Invoke-PostInstallMonitor -Component $comp

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*Action script not found*"
        }
    }

    # ----------------------------------------------------------------------
    # STOP CONDITION TRUE
    # ----------------------------------------------------------------------

    It "logs when StopCondition returns true" {

        $comp = New-PostInstallComponent `
            -StartCondition { param($ctx) $true } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $true }

        Invoke-PostInstallMonitor -Component $comp

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -like "*StopCondition met*"
        }
    }

    # ----------------------------------------------------------------------
    # STOP CONDITION FALSE
    # ----------------------------------------------------------------------

    It "does not log StopCondition when it returns false" {

        $comp = New-PostInstallComponent `
            -StartCondition { param($ctx) $true } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        Invoke-PostInstallMonitor -Component $comp

        Assert-MockCalled Write-Timestamped -ParameterFilter {
            $Message -notlike "*StopCondition met*"
        }
    }

    # ----------------------------------------------------------------------
    # COMPONENT REGISTRY UPDATED PER COMPONENT
    # ----------------------------------------------------------------------

    It "sets ComponentRegistry for each component before execution" {

        $script:seenRegistry = $null

        $comp = New-PostInstallComponent `
            -StartCondition {
                param($ctx)
                $script:seenRegistry = $ctx.ComponentRegistry
                $true
            } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        Invoke-PostInstallMonitor -Component $comp

        $script:seenRegistry | Should -Be "HKCU:\Software\MyCompany\PostInstall\Components\$($comp.Name)"
    }

    # ----------------------------------------------------------------------
    # MULTIPLE COMPONENTS EXECUTED IN ORDER
    # ----------------------------------------------------------------------

    It "executes multiple components in order" {

        $script:order = @()

        $c1 = New-PostInstallComponent `
            -StartCondition { param($ctx) $script:order += "c1"; $false } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        $c2 = New-PostInstallComponent `
            -StartCondition { param($ctx) $script:order += "c2"; $false } `
            -Action { param($ctx) } `
            -StopCondition { param($ctx) $false }

        Invoke-PostInstallMonitor -Component @($c1, $c2)

        $script:order[0] | Should -Be "c1"
        $script:order[1] | Should -Be "c2"
    }
}

Describe "PostInstallMonitor - Component Loader Behavior" {

    BeforeAll {
        $here = Split-Path -Parent $PSCommandPath
        . "$here\..\PostInstallMonitor.ps1"
        . "$here\..\PostInstallAction.ps1"
    }

    BeforeEach {

        # Replace Write-Timestamped with a stub that writes to output
        function global:Write-Timestamped {
            param($Message)
            Write-Output $Message
        }

        # Basic mocks
        Mock Start-Sleep {}
        Mock Get-ItemProperty { @{ ActionRequired = 1; ActionCompleted = 0 } }
        Mock Set-ItemProperty {}
        function global:Get-CurrentLogonId { 3333 }
        Mock Get-CimInstance { [pscustomobject]@{ LastBootUpTime = (Get-Date).AddHours(-1) } }
        Mock Invoke-PostInstallAction {}
        Mock Invoke-PostInstallMonitor {}

        # Create real Components folder
        $componentsDir = Join-Path $here "..\Components"
        New-Item -ItemType Directory -Path $componentsDir -Force | Out-Null
        
        Remove-Variable Component -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable Component -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable Component -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Item -Recurse -Force (Join-Path $here "..\Components") -ErrorAction SilentlyContinue
    }

    # ----------------------------------------------------------------------
    # MULTIPLE COMPONENT FILES LOADED
    # ----------------------------------------------------------------------

    It "loads all component files from the Components folder" {

        $componentsDir = Join-Path $here "..\Components"

        @"
`$Component = New-PostInstallComponent -StartCondition { param(\$ctx) \$false } -Action { param(\$ctx) } -StopCondition { param(\$ctx) \$false }
"@ | Set-Content (Join-Path $componentsDir "A.ps1")

        @"
`$Component = New-PostInstallComponent -StartCondition { param(\$ctx) \$false } -Action { param(\$ctx) } -StopCondition { param(\$ctx) \$false }
"@ | Set-Content (Join-Path $componentsDir "B.ps1")

        . "$here\..\PostInstallMonitor.ps1"
        $output = & "$here\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match "Component loader started"
        Assert-MockCalled Invoke-PostInstallMonitor -Times 1
    }

    # ----------------------------------------------------------------------
    # COMPONENT FILE MISSING $Component VARIABLE
    # ----------------------------------------------------------------------

    It "skips component files that do not define `$Component" {

        $componentsDir = Join-Path $here "..\Components"

        @"
Write-Output 'Invalid file'
"@ | Set-Content (Join-Path $componentsDir "Bad.ps1")


        . "$here\..\PostInstallMonitor.ps1"
        $output = & "$here\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match 'ERROR: Component file '\''Bad\.ps1'\'' did not define a \$Component variable\. Skipping\.'
    }

    # ----------------------------------------------------------------------
    # COMPONENT FILE WITH INVALID SCRIPTBLOCKS
    # ----------------------------------------------------------------------

    It "skips component files missing required scriptblocks" {

        $componentsDir = Join-Path $here "..\Components"

        @"
`$Component = [pscustomobject]@{
    Name = 'Invalid'
    StartCondition = `$null
    Action         = `$null
    StopCondition  = `$null
}
"@ | Set-Content (Join-Path $componentsDir "Invalid.ps1")

        . "$here\..\PostInstallMonitor.ps1"
        $output = & "$here\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match "ERROR: Component 'Invalid\.ps1' is missing required scriptblocks"
    }

    # ----------------------------------------------------------------------
    # COMPONENT FILE LOAD ERROR
    # ----------------------------------------------------------------------

    It "logs an error when a component file fails to load" {

        $componentsDir = Join-Path $here "..\Components"

        @"
throw 'Load failure'
"@ | Set-Content (Join-Path $componentsDir "Error.ps1")

        . "$here\..\PostInstallMonitor.ps1"
        $output = & "$here\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match "ERROR: Failed to load component 'Error\.ps1'"
    }

    # ----------------------------------------------------------------------
    # FALLBACK TO DEFAULT COMPONENT WHEN NONE LOADED
    # ----------------------------------------------------------------------

    It "falls back to default component when no valid components load" {

        # No files created

        . "$here\..\PostInstallMonitor.ps1"
        $output = & "$here\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match "Component loader started"
        Assert-MockCalled Invoke-PostInstallMonitor -Times 1 -ParameterFilter { $Component -eq $null }
    }

    # ----------------------------------------------------------------------
    # SINGLE COMPONENT FILE LOADED
    # ----------------------------------------------------------------------

    It "loads Component.ps1 when Components folder is missing" {

        Remove-Item -Recurse -Force (Join-Path $here "..\Components") -ErrorAction SilentlyContinue

        @"
`$Component = New-PostInstallComponent -StartCondition { param(\$ctx) \$false } -Action { param(\$ctx) } -StopCondition { param(\$ctx) \$false }
"@ | Set-Content (Join-Path $here "..\Component.ps1")

        . "$here\..\PostInstallMonitor.ps1"
        $output = & "$here\..\PostInstallMonitor.ps1" *>&1
        $text   = $output -join "`n"

        $text | Should -Match "Component loader started"
        Assert-MockCalled Invoke-PostInstallMonitor -Times 1

        Remove-Item (Join-Path $here "..\Component.ps1") -Force
    }
}
