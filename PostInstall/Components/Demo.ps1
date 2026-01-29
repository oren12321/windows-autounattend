. (Join-Path $PSScriptRoot '..\Monitor\New-PostInstallComponent.ps1')

# DemoComponent.ps1
# -------------------------------------------------------------------
# This is a toy example showing how to create a PostInstall component.
#
# It demonstrates:
#   - How to define a component using New-PostInstallComponent
#   - How StartCondition / Action / StopCondition work
#   - How to use the $context object
#   - How to log messages using $context.Log
#   - How to inspect the context fields
#   - How to write component-specific state to the registry
#
# IMPORTANT:
#   The $context object is provided by the monitor and should be treated
#   as READ-ONLY by components. It contains information about the current
#   execution environment and some values that the monitor persists.
#
#   Components should NOT modify:
#       - $context.UserName
#       - $context.UserProfile
#       - $context.LocalAppData
#       - $context.ProgramData
#       - $context.LogonId
#       - $context.BootTime
#       - $context.Now
#       - $context.Log
#       - Any persisted values written by the monitor
#
#   Components MAY write their own custom values under:
#       $context.ComponentRegistry
#
#   This keeps the system predictable and prevents components from
#   corrupting global or versioning state.
# -------------------------------------------------------------------

$Component = New-PostInstallComponent `
    -Name "DemoComponent" `
    -Reset {
        param($context)
        
        # Reset is for component initialization, and not for
        # rewinding it such that StartCondition will be true.
        $context.Log("DemoComponent: Reset called.")
    } `
    -StartCondition {
        param($context)

        # StartCondition is called before the component runs.
        # Return $true to allow execution, $false to skip.
        $context.Log("DemoComponent: StartCondition called.")
        $true
    } `
    -Action {
        param($context)

        $context.Log("DemoComponent: Action started.")

        # Demonstrate reading context fields
        $context.Log("Context.UserName        = $($context.UserName)")
        $context.Log("Context.UserProfile     = $($context.UserProfile)")
        $context.Log("Context.LocalAppData    = $($context.LocalAppData)")
        $context.Log("Context.ProgramData     = $($context.ProgramData)")
        $context.Log("Context.LogonId         = $($context.LogonId)")
        $context.Log("Context.BootTime        = $($context.BootTime)")
        $context.Log("Context.Now             = $($context.Now)")
        $context.Log("Context.ComponentRegistry = $($context.ComponentRegistry)")

        # IMPORTANT:
        # Do NOT modify any of the context fields.
        # They are provided by the monitor and represent the current
        # execution environment. Treat them as read-only.

        # Demonstrate writing component-specific state
        $reg = $context.ComponentRegistry
        if (-not (Test-Path $reg)) {
            New-Item -Path $reg -Force | Out-Null
        }

        # Components may write their own values under their registry root.
        New-ItemProperty -Path $reg -Name "DemoValue" -Value "Hello from DemoComponent" -PropertyType String -Force | Out-Null
        $context.Log("DemoComponent: Wrote DemoValue to registry.")

        $context.Log("DemoComponent: Action finished.")
    } `
    -StopCondition {
        param($context)

        # StopCondition is called after Action.
        # Return $true to indicate the component is satisfied.
        $context.Log("DemoComponent: StopCondition called.")
        $true
    } `
    -Cleanup {
        param($context)
        
        # Cleanup is being used to remove or release
        # resources that has been used by this component.
        $context.Log("DemoComponent: Cleanup called.")
    }