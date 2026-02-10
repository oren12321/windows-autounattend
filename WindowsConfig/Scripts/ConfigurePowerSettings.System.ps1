. "C:\MySetup\Scripts\Apply-Registry.ps1"

Write-Output "Setting up power plan: High Performance Laptop Plan..."

$customPlanGuid = "57696e68-616e-6365-506f-776572000000"

$existingPlan = powercfg /query $customPlanGuid 2>&1
$planExists = $LASTEXITCODE -eq 0

if ($planExists) {
    Write-Output "Power plan already exists, using existing plan"
} else {
    Write-Output "Creating new power plan..."
    $planCreated = $false

    $sourceSchemes = @(
        @{ Name = "Ultimate Performance"; Guid = "e9a42b02-d5df-448d-aa00-03f14749eb61" },
        @{ Name = "High Performance"; Guid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" },
        @{ Name = "Balanced"; Guid = "381b4222-f694-41f0-9685-ff5bb260df2e" }
    )

    foreach ($scheme in $sourceSchemes) {
        Write-Output "Attempting to duplicate from $($scheme.Name)..."
        $result = powercfg /duplicatescheme $($scheme.Guid) $customPlanGuid 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Successfully created from $($scheme.Name)"
            powercfg /changename $customPlanGuid "High Performance Laptop Plan" | Out-Null
            $planCreated = $true
            break
        }
    }

    if (-not $planCreated) {
        Write-Output "Failed to create power plan"
    }
}

Write-Output "Disabling hibernation..."
powercfg /hibernate on 2>$null
Write-Output "Hibernation enabled"

Write-Output "Enabling hidden power settings..."
$PowerSettingsBasePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$hiddenSettings = @(
    @{ Subgroup = "2a737441-1930-4402-8d77-b2bebba308a3"; Setting = "0853a681-27c8-4100-a2fd-82013e970683" },
    @{ Subgroup = "2a737441-1930-4402-8d77-b2bebba308a3"; Setting = "d4e98f31-5ffe-4ce1-be31-1b38b384c009" },
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "7648efa3-dd9c-4e3e-b566-50f929386280" },
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "96996bc0-ad50-47ec-923b-6f41874dd9eb" },
    @{ Subgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "5ca83367-6e45-459f-a27b-476b1d01c936" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "94d3a615-a899-4ac5-ae2b-e4d8f634367f" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "be337238-0d82-4146-a960-4f3749d470c7" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "465e1f50-b610-473a-ab58-00d1077dc418" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "40fbefc7-2e9d-4d25-a185-0cfd8574bac6" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "0cc5b647-c1df-4637-891a-dec35c318583" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "ea062031-0e34-4ff1-9b6d-eb1059334028" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "06cadf0e-64ed-448a-8927-ce7bf90eb35d" },
    @{ Subgroup = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" }
)

foreach ($item in $hiddenSettings) {
    $regPath = Join-Path $PowerSettingsBasePath "$($item.Subgroup)\$($item.Setting)"
    Apply-RegistryEntry -Path $regPath -Name "Attributes" -Type "DWord" -Value 0
}

Write-Output "Applying power settings..."

$settings = @(

    <#
    #===============================================================================
    # Turn off display after
    #
    # Description:
    #   Controls how long the system waits before turning off the display due to
    #   inactivity. A longer timeout improves comfort and prevents interruptions,
    #   while a shorter timeout reduces power consumption and prevents burn‑in on
    #   OLED/IPS panels. This setting affects only the display, not system sleep.
    #
    # Options:
    #   Continuous range: 0–86400 seconds (0 = never turn off)
    #
    # Recommended:
    #   AC = 600 — Provides a comfortable 10‑minute window without wasting energy.
    #   DC = 180 — Saves significant battery life while still being user‑friendly.
    #===============================================================================
    #>
    @{ S="7516b95f-f776-4464-8c53-06167f40cc99"; G="3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"; AC=600; DC=180 },

    <#
    #===============================================================================
    # Turn off hard disk after
    #
    # Description:
    #   Determines how long the system waits before spinning down mechanical hard
    #   drives. SSDs ignore this setting entirely, but HDDs benefit from reduced
    #   power usage when idle. Too short a timeout can cause frequent spin‑ups,
    #   reducing drive lifespan and causing delays.
    #
    # Options:
    #   Continuous range: 0–86400 seconds (0 = never spin down)
    #
    # Recommended:
    #   AC = 0 — Prevents unnecessary spin‑down delays and wear on HDDs.
    #   DC = 600 — Saves battery on HDD‑based systems without excessive cycling.
    #===============================================================================
    #>
    @{ S="0012ee47-9041-4b5d-9b77-535fba8b1442"; G="6738e2c4-e8a5-4a42-b16a-e040e769756e"; AC=0; DC=600 },

    <#
    #===============================================================================
    # JavaScript timer frequency
    #
    # Description:
    #   Controls how aggressively Windows coalesces JavaScript timers in browsers
    #   and UWP apps. Lower frequencies save power by batching timer events, while
    #   higher frequencies improve responsiveness and animation smoothness. This
    #   setting primarily affects web browsing and UI responsiveness.
    #
    # Options:
    #   0 = Maximum power savings (coalesced timers)
    #   1 = Maximum performance (high‑resolution timers)
    #
    # Recommended:
    #   AC = 1 — Ensures smooth UI interactions and responsive web applications.
    #   DC = 0 — Reduces background CPU wakeups and extends battery life.
    #===============================================================================
    #>
    @{ S="02f815b5-a5cf-4c84-bf20-649d1f75d3d8"; G="4c793e7d-a264-42e1-87d3-7a0d2f523ccd"; AC=1; DC=0 },

    <#
    #===============================================================================
    # Desktop background slideshow
    #
    # Description:
    #   Controls whether Windows rotates wallpaper images automatically. This setting
    #   uses inverted logic: 0 means slideshow is allowed, 1 means slideshow is
    #   paused. Allowing slideshows increases GPU wakeups and background activity,
    #   which can reduce battery life on portable devices.
    #
    # Options:
    #   0 = Slideshow available (NOT paused)
    #   1 = Slideshow paused
    #
    # Recommended:
    #   AC = 0 — Cosmetic feature is fine on AC power with negligible impact.
    #   DC = 1 — Prevents unnecessary GPU activity and saves battery.
    #===============================================================================
    #>
    @{ S="0d7dbae2-4294-402a-ba8e-26777e8488cd"; G="309dce9b-bef4-4119-9921-a851fb12f0f4"; AC=0; DC=0 },

    <#
    #===============================================================================
    # Wireless adapter power saving
    #
    # Description:
    #   Adjusts how aggressively the Wi‑Fi adapter reduces power usage. Higher power
    #   saving modes reduce throughput and increase latency, while performance mode
    #   keeps the radio fully active. This setting has a noticeable effect on both
    #   network responsiveness and battery life.
    #
    # Options:
    #   0 = Maximum performance
    #   1 = Low power saving
    #   2 = Medium power saving
    #   3 = Maximum power saving
    #
    # Recommended:
    #   AC = 0 — Ensures maximum throughput and lowest latency for high‑performance
    #            workloads such as streaming, gaming, and large file transfers.
    #   DC = 2 — Provides a balanced compromise between battery life and stable,
    #            responsive Wi‑Fi performance.
    #===============================================================================
    #>
    @{ S="19cbb8fa-5279-450e-9fac-8a3d5fedd0c1"; G="12bbebe6-58d6-4636-95bb-3217ef867c1a"; AC=0; DC=2 },

    <#
    #===============================================================================
    # Sleep after
    #
    # Description:
    #   Determines how long the system remains idle before entering sleep mode.
    #   Sleep reduces power consumption significantly while allowing fast resume.
    #   On AC power, automatic sleep can interrupt long-running tasks, while on
    #   battery it prevents unnecessary drain during periods of inactivity.
    #
    # Options:
    #   Continuous range: 0–86400 seconds (0 = never sleep automatically)
    #
    # Recommended:
    #   AC = 0   — Prevents the system from sleeping during workloads, updates,
    #              downloads, or long-running tasks where performance and uptime
    #              matter more than power savings.
    #   DC = 900 — A 15‑minute timeout provides meaningful battery savings while
    #              still allowing the user to resume work quickly.
    #===============================================================================
    #>
    @{ S="238c9fa8-0aad-41ed-83f4-97be242c8f20"; G="29f6c1db-86da-48c5-9fdb-f2b67b1f44da"; AC=0; DC=900 },

    <#
    #===============================================================================
    # Allow wake timers
    #
    # Description:
    #   Controls whether scheduled tasks, maintenance operations, or Windows Update
    #   are allowed to wake the system from sleep. Allowing wake timers ensures
    #   important maintenance tasks occur on schedule, but can cause unexpected
    #   wake-ups—especially problematic on battery power.
    #
    # Options:
    #   0 = Disabled (no wake timers allowed)
    #   1 = Enabled (all wake timers allowed)
    #   2 = Important wake timers only (recommended default)
    #
    # Recommended:
    #   AC = 1   — Allows critical system tasks (updates, maintenance) to run while
    #              preventing unnecessary wake-ups from nonessential tasks.
    #   DC = 0   — Prevents the system from waking unexpectedly and draining the
    #              battery when the device is not in use.
    #===============================================================================
    #>
    @{ S="238c9fa8-0aad-41ed-83f4-97be242c8f20"; G="bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d"; AC=2; DC=2 },

    <#
    #===============================================================================
    # Hibernate after
    #
    # Description:
    #   Specifies how long the system remains in sleep before transitioning to
    #   hibernate. Hibernate consumes almost no power and preserves the session
    #   even if the battery depletes. On AC power, hibernation is rarely needed,
    #   but on battery it prevents data loss during extended idle periods.
    #
    # Options:
    #   Continuous range: 0–86400 seconds (0 = never hibernate automatically)
    #
    # Recommended:
    #   AC = 0      — Avoids unnecessary hibernation transitions that slow down
    #                 resume performance when AC power is available.
    #   DC = 10800  — A 3‑hour timeout protects against battery drain during long
    #                 idle periods while still allowing convenient resume.
    #===============================================================================
    #>
    @{ S="238c9fa8-0aad-41ed-83f4-97be242c8f20"; G="9d7815a6-7ee4-497e-8888-515a05f02364"; AC=0; DC=10800 },

    <#
    #===============================================================================
    # Allow hybrid sleep
    #
    # Description:
    #   Hybrid sleep combines sleep and hibernate by saving memory contents to disk
    #   while also entering low‑power sleep. This protects against power loss while
    #   maintaining fast wake times. On AC power, the safety benefit is minimal,
    #   but on battery it provides protection if the battery depletes unexpectedly.
    #
    # Options:
    #   0 = Off
    #   1 = On
    #
    # Recommended:
    #   AC = 0   — Disabling hybrid sleep improves sleep/wake speed and reduces
    #              unnecessary disk writes on systems with stable AC power.
    #   DC = 1   — Enables data protection in case the battery drains completely
    #              while the system is sleeping.
    #===============================================================================
    #>
    @{ S="238c9fa8-0aad-41ed-83f4-97be242c8f20"; G="94ac6d29-73ce-41a6-809f-6363ba21b47e"; AC=0; DC=1 },

    <#
    #===============================================================================
    # USB idle timeout
    #
    # Description:
    #   Determines how long USB hubs and controllers wait before entering a low‑power
    #   idle state. Shorter timeouts save power but may cause issues with devices
    #   that do not handle aggressive power transitions well. Longer timeouts improve
    #   compatibility at the cost of slightly higher power usage.
    #
    # Options:
    #   Continuous timeout value (unit varies by hardware implementation)
    #
    # Recommended:
    #   AC = 50   — Provides a reasonable delay that avoids unnecessary power
    #               transitions while maintaining compatibility with most devices.
    #   DC = 50   — USB idle power savings are modest; using the same value avoids
    #               device instability while still allowing some power reduction.
    #===============================================================================
    #>
    @{ S="2a737441-1930-4402-8d77-b2bebba308a3"; G="0853a681-27c8-4100-a2fd-82013e970683"; AC=50; DC=50 },

    <#
    #===============================================================================
    # USB selective suspend
    #
    # Description:
    #   Controls whether Windows may suspend individual USB ports or devices when
    #   they are idle. This reduces power consumption by preventing unnecessary
    #   device polling. Most modern USB devices handle selective suspend correctly,
    #   but some older peripherals may behave unpredictably if aggressively powered
    #   down. Keeping this enabled generally provides meaningful power savings with
    #   minimal compatibility issues.
    #
    # Options:
    #   0 = Disabled
    #   1 = Enabled
    #
    # Recommended:
    #   AC = 1 — Safe for nearly all devices and avoids wasting power on idle USB
    #            peripherals without affecting performance.
    #   DC = 1 — Helps extend battery life by reducing background USB activity while
    #            maintaining compatibility with modern hardware.
    #===============================================================================
    #>
    @{ S="2a737441-1930-4402-8d77-b2bebba308a3"; G="48e6b7a6-50f5-4782-a5d4-53bb8f07e226"; AC=1; DC=1 },

    <#
    #===============================================================================
    # USB 3 link‑state power management
    #
    # Description:
    #   Determines how aggressively USB 3.0 ports enter low‑power link states when
    #   idle. Higher power‑saving modes reduce energy usage but may introduce slight
    #   latency when waking devices. Most USB 3 devices tolerate these transitions
    #   well, but extremely aggressive settings can cause intermittent disconnects
    #   on poorly designed hardware.
    #
    # Options:
    #   0 = Off
    #   1 = Moderate power savings
    #   2 = Maximum power savings
    #
    # Recommended:
    #   AC = 1 — Provides a balanced approach that avoids unnecessary latency while
    #            still reducing some idle power consumption.
    #   DC = 2 — Maximizes battery savings by allowing deeper link‑state power
    #            reductions during idle periods.
    #===============================================================================
    #>
    @{ S="2a737441-1930-4402-8d77-b2bebba308a3"; G="d4e98f31-5ffe-4ce1-be31-1b38b384c009"; AC=1; DC=2 },

    <#
    #===============================================================================
    # Intel integrated graphics power plan
    #
    # Description:
    #   Adjusts the power/performance behavior of Intel integrated graphics. Higher
    #   performance modes improve rendering speed and responsiveness, while lower
    #   modes reduce GPU frequency and voltage to save power. This setting affects
    #   video playback, UI smoothness, and GPU‑accelerated workloads.
    #
    # Options (typical Intel mapping):
    #   0 = Maximum battery life
    #   1 = Balanced
    #   2 = Maximum performance
    #
    # Recommended:
    #   AC = 2 — Ensures the GPU runs at full capability for smooth UI performance,
    #            video playback, and GPU‑accelerated tasks.
    #   DC = 1 — Balanced mode reduces power usage while maintaining acceptable
    #            responsiveness for everyday tasks.
    #===============================================================================
    #>
    @{ S="44f3beca-a7c0-460e-9df2-bb8b99e0cba6"; G="3619c3f2-afb2-4afc-b0e9-e7fef372de36"; AC=2; DC=1 },

    <#
    #===============================================================================
    # Power button action
    #
    # Description:
    #   Defines what happens when the physical power button is pressed. Choosing
    #   sleep provides a fast, convenient way to pause work without shutting down.
    #   More drastic actions like shutdown or hibernate are typically unnecessary
    #   for a high‑performance configuration unless specifically required.
    #
    # Options:
    #   0 = Do nothing
    #   1 = Sleep
    #   2 = Hibernate
    #   3 = Shut down
    #
    # Recommended:
    #   AC = 1 — Sleep offers the best balance of convenience and speed, allowing
    #            quick resume without interrupting workflows.
    #   DC = 1 — Consistent behavior across power states avoids confusion and still
    #            conserves battery effectively.
    #===============================================================================
    #>
    @{ S="4f971e89-eebd-4455-a8de-9e59040e7347"; G="7648efa3-dd9c-4e3e-b566-50f929386280"; AC=1; DC=1 },

    <#
    #===============================================================================
    # Sleep button action
    #
    # Description:
    #   Determines the action taken when the dedicated sleep button (if present) is
    #   pressed. Sleep is the most intuitive and least disruptive behavior for this
    #   button, providing quick suspend/resume without data loss or long delays.
    #
    # Options:
    #   0 = Do nothing
    #   1 = Sleep
    #   2 = Hibernate
    #   3 = Shut down
    #
    # Recommended:
    #   AC = 1 — Ensures the sleep button behaves consistently with user expectations
    #            and provides fast suspend/resume functionality.
    #   DC = 1 — Maintains consistent behavior and conserves battery effectively
    #            without forcing full hibernation.
    #===============================================================================
    #>
    @{ S="4f971e89-eebd-4455-a8de-9e59040e7347"; G="96996bc0-ad50-47ec-923b-6f41874dd9eb"; AC=1; DC=1 },

    <#
    #===============================================================================
    # Lid close action
    #
    # Description:
    #   Determines what happens when the laptop lid is closed. This is one of the
    #   most important mobility‑related settings. Closing the lid is a natural and
    #   frequent action, so the behavior must be predictable. Sleep is the most
    #   intuitive and least disruptive choice, preserving the session while reducing
    #   power usage. More drastic actions (shutdown/hibernate) can interrupt work or
    #   cause delays. "Do nothing" is risky because the system may overheat in a bag.
    #
    # Options:
    #   0 = Do nothing
    #   1 = Sleep
    #   2 = Hibernate
    #   3 = Shut down
    #
    # Recommended:
    #   AC = 1 — Sleep provides fast resume and avoids accidental shutdowns while
    #            still reducing power usage when the lid is closed.
    #   DC = 1 — Ensures consistent behavior and prevents overheating in bags while
    #            still conserving battery effectively.
    #===============================================================================
    #>
    @{ S="4f971e89-eebd-4455-a8de-9e59040e7347"; G="5ca83367-6e45-459f-a27b-476b1d01c936"; AC=1; DC=1 },

    <#
    #===============================================================================
    # PCI Express ASPM (Active State Power Management)
    #
    # Description:
    #   Controls how aggressively PCI Express devices enter low‑power link states.
    #   Higher power‑saving modes reduce energy usage but may introduce additional
    #   latency when waking devices. Some older or poorly designed PCIe hardware may
    #   behave unpredictably with aggressive ASPM settings. On AC power, performance
    #   and stability are typically prioritized, while on battery moderate savings
    #   are beneficial without risking device issues.
    #
    # Options:
    #   0 = Off
    #   1 = Moderate power savings
    #   2 = Maximum power savings
    #
    # Recommended:
    #   AC = 0 — Ensures maximum stability and avoids any latency penalties for
    #            high‑performance workloads or sensitive PCIe devices.
    #   DC = 1 — Provides meaningful battery savings without the risks associated
    #            with the most aggressive ASPM mode.
    #===============================================================================
    #>
    @{ S="501a4d13-42af-4429-9fd1-a8218c268e20"; G="ee12f906-d277-404b-b6da-e5fa1a576df5"; AC=0; DC=1 },

    <#
    #===============================================================================
    # Minimum processor state
    #
    # Description:
    #   Defines the lowest CPU performance level (as a percentage of maximum) that
    #   the processor is allowed to drop to. Lower minimum states allow deeper idle
    #   power savings, reducing heat and extending battery life. Setting this too
    #   high prevents the CPU from entering efficient low‑power states and wastes
    #   energy. Modern CPUs handle low idle states extremely well, so low values are
    #   generally optimal.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 5 — Allows the CPU to idle efficiently without affecting performance
    #            during active workloads.
    #   DC = 5 — Provides strong battery savings while maintaining responsiveness
    #            thanks to modern CPU power management.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="893dee8e-2bef-41e0-89c6-b55d0929964c"; AC=5; DC=5 },

    <#
    #===============================================================================
    # Maximum processor state
    #
    # Description:
    #   Sets the highest CPU performance level allowed. A value of 100% enables full
    #   turbo/boost performance. Reducing this value can significantly lower power
    #   consumption and heat output, especially on battery, but also reduces peak
    #   performance. On AC power, limiting maximum performance is rarely desirable.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 100 — Ensures full CPU performance for demanding workloads, gaming,
    #              virtualization, and multitasking.
    #   DC = 85  — Reduces heat and power spikes on battery while maintaining strong
    #              performance for typical mobile workloads.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="bc5038f7-23e0-4960-96da-33abaf5935ec"; AC=100; DC=85 },

    <#
    #===============================================================================
    # System cooling policy
    #
    # Description:
    #   Determines whether the system should increase fan speed (active cooling) or
    #   reduce CPU frequency (passive cooling) when temperatures rise. Active cooling
    #   maintains performance but increases fan noise and power usage. Passive cooling
    #   reduces heat and noise but may throttle performance. On AC power, performance
    #   is typically prioritized; on battery, efficiency and noise reduction matter.
    #
    # Options:
    #   0 = Passive (throttle CPU first)
    #   1 = Active (increase fan speed first)
    #
    # Recommended:
    #   AC = 1 — Prioritizes performance and prevents unnecessary throttling during
    #            heavy workloads.
    #   DC = 0 — Reduces fan usage and power consumption, extending battery life and
    #            keeping the device quieter.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="94d3a615-a899-4ac5-ae2b-e4d8f634367f"; AC=1; DC=0 },

    <#
    #===============================================================================
    # Processor performance boost mode
    #
    # Description:
    #   Controls how aggressively the CPU engages turbo/boost frequencies. Higher
    #   boost modes allow the processor to rapidly increase clock speeds for short,
    #   intensive workloads, improving responsiveness and performance. However,
    #   aggressive boosting increases power consumption and heat output. Efficient
    #   modes reduce power draw while still allowing limited boosting when needed.
    #
    # Options:
    #   0 = Disabled (no boost)
    #   1 = Enabled (standard boost)
    #   2 = Aggressive (maximum boost behavior)
    #   3 = Efficient aggressive (balanced boost with efficiency bias)
    #   4 = Efficient (minimal boost, power‑focused)
    #
    # Recommended:
    #   AC = 2 — Ensures maximum responsiveness and performance for demanding tasks,
    #            taking full advantage of turbo capabilities.
    #   DC = 3 — Provides a strong balance between performance and battery life by
    #            allowing boost but with efficiency‑oriented behavior.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="be337238-0d82-4146-a960-4f3749d470c7"; AC=2; DC=3 },

    <#
    #===============================================================================
    # Legacy PPM increase policy
    #
    # Description:
    #   Determines how aggressively the CPU increases its frequency when load rises.
    #   A more aggressive policy results in faster ramp‑up to higher frequencies,
    #   improving responsiveness but consuming more power. Conservative policies
    #   reduce power usage but may feel less snappy during sudden bursts of activity.
    #
    # Options:
    #   0 = Balanced
    #   1 = Conservative (slow increase)
    #   2 = Aggressive (fast increase)
    #
    # Recommended:
    #   AC = 2 — Ensures the CPU responds quickly to workload spikes, improving
    #            system responsiveness and reducing perceived lag.
    #   DC = 0 — Balanced behavior avoids unnecessary power spikes while still
    #            providing adequate responsiveness for mobile use.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="465e1f50-b610-473a-ab58-00d1077dc418"; AC=2; DC=0 },

    <#
    #===============================================================================
    # Legacy PPM decrease policy
    #
    # Description:
    #   Controls how quickly the CPU reduces its frequency when load decreases.
    #   A fast decrease saves power by dropping clocks immediately, while a slower
    #   decrease maintains performance by keeping higher frequencies active longer.
    #   This setting influences both responsiveness and energy efficiency.
    #
    # Options:
    #   0 = Balanced
    #   1 = Slow decrease (hold higher clocks longer)
    #   2 = Fast decrease (drop clocks quickly)
    #
    # Recommended:
    #   AC = 1 — Maintains higher performance levels during brief idle periods,
    #            improving responsiveness in bursty workloads.
    #   DC = 2 — Reduces power consumption by quickly lowering CPU frequency when
    #            load drops, extending battery life.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="40fbefc7-2e9d-4d25-a185-0cfd8574bac6"; AC=1; DC=2 },

    <#
    #===============================================================================
    # Core parking minimum cores
    #
    # Description:
    #   Specifies the minimum percentage of CPU cores that must remain unparked
    #   (active) even during low system load. Lower values allow more cores to be
    #   parked, reducing power consumption but potentially increasing latency when
    #   workloads resume. Higher values keep more cores active, improving parallel
    #   responsiveness at the cost of increased power usage.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 50 — Keeps enough cores active to maintain strong responsiveness for
    #             multitasking and parallel workloads.
    #   DC = 25 — Allows more aggressive core parking to save battery while still
    #             keeping enough cores available for smooth operation.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="0cc5b647-c1df-4637-891a-dec35c318583"; AC=50; DC=25 },

    <#
    #===============================================================================
    # Core parking maximum cores
    #
    # Description:
    #   Defines the maximum percentage of CPU cores that may remain unparked during
    #   system activity. Setting this to 100% allows all cores to become active when
    #   needed, ensuring full performance. Lower values artificially limit the number
    #   of active cores, reducing performance but saving power.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 100 — Ensures the CPU can utilize all available cores for demanding
    #              workloads, maximizing performance.
    #   DC = 100 — Allows full multicore performance when required, while other
    #              power‑saving mechanisms handle efficiency.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="ea062031-0e34-4ff1-9b6d-eb1059334028"; AC=100; DC=100 },

    <#
    #===============================================================================
    # HWP Energy Performance Preference (EPP)
    #
    # Description:
    #   Provides a hint to the CPU’s hardware power management system (HWP) about
    #   whether to prioritize performance or energy efficiency. Lower values push
    #   the CPU toward higher frequencies and faster responsiveness, while higher
    #   values encourage lower frequencies, reduced voltage, and longer battery life.
    #   This setting is highly effective on modern Intel and AMD processors that
    #   support hardware-guided performance states.
    #
    # Options:
    #   Continuous range: 0–100
    #     0   = Maximum performance bias
    #     100 = Maximum efficiency bias
    #
    # Recommended:
    #   AC = 0–10 — Ensures the CPU aggressively prioritizes performance, delivering
    #               fast responsiveness and maximum throughput for demanding tasks.
    #   DC = 40–50 — Provides a balanced efficiency mode that significantly reduces
    #                power draw while maintaining smooth everyday performance.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="36687f9e-e3a5-4dbf-b1dc-15eb381c6863"; AC=10; DC=45 },

    <#
    #===============================================================================
    # Legacy PPM increase threshold
    #
    # Description:
    #   Defines the CPU utilization percentage at which the processor begins raising
    #   its frequency. Lower thresholds cause the CPU to ramp up more quickly in
    #   response to small workloads, improving responsiveness. Higher thresholds
    #   delay frequency increases, reducing power consumption but potentially making
    #   the system feel less responsive during light or bursty workloads.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 10 — Ensures the CPU reacts quickly to workload changes, improving
    #             responsiveness for interactive tasks and multitasking.
    #   DC = 30 — Reduces unnecessary frequency boosts on battery, improving battery
    #             life while still allowing boosts when workloads become heavier.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="06cadf0e-64ed-448a-8927-ce7bf90eb35d"; AC=10; DC=30 },

    <#
    #===============================================================================
    # Legacy PPM decrease threshold
    #
    # Description:
    #   Determines the CPU utilization percentage at which the processor begins
    #   lowering its frequency. Lower thresholds cause the CPU to drop clocks sooner,
    #   saving power but potentially reducing responsiveness. Higher thresholds keep
    #   the CPU at higher frequencies longer, improving performance at the cost of
    #   increased power usage.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 8  — Keeps the CPU at higher frequencies slightly longer, improving
    #             responsiveness during short idle gaps in active workloads.
    #   DC = 20 — Allows the CPU to reduce frequency sooner, improving battery life
    #             without noticeably affecting typical mobile performance.
    #===============================================================================
    #>
    @{ S="54533251-82be-4824-96c1-47b60b740d00"; G="12a0ab44-fe28-4fa9-b3bd-4b64f44960a6"; AC=8; DC=20 },

    <#
    #===============================================================================
    # Multimedia: sharing media
    #
    # Description:
    #   Controls how the system behaves when sharing or streaming media over the
    #   network. Preventing sleep ensures uninterrupted playback or streaming, while
    #   allowing sleep conserves power but may interrupt media sessions. Away Mode
    #   keeps the system awake without turning on the display, useful for media
    #   servers or HTPC setups.
    #
    # Options:
    #   0 = Allow the computer to sleep
    #   1 = Prevent the computer from sleeping
    #   2 = Allow Away Mode
    #
    # Recommended:
    #   AC = 1 — Prevents interruptions during streaming or media sharing, ensuring
    #            stable playback and uninterrupted network availability.
    #   DC = 0 — Allows the system to sleep normally, preventing unnecessary battery
    #            drain when media sharing is not essential on battery power.
    #===============================================================================
    #>
    @{ S="9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; G="03680956-93bc-4294-bba6-4e0f09bb717f"; AC=1; DC=0 },

    <#
    #===============================================================================
    # Multimedia: video playback performance bias
    #
    # Description:
    #   Determines whether video playback should prioritize image quality or power
    #   efficiency. Higher quality modes may increase GPU usage, improving sharpness
    #   and smoothness. Power-saving modes reduce GPU load, extending battery life
    #   but potentially lowering playback quality or frame consistency.
    #
    # Options:
    #   0 = Video playback quality bias
    #   1 = Balanced
    #   2 = Power-saving bias
    #
    # Recommended:
    #   AC = 0 — Ensures the best possible video quality, taking advantage of AC
    #            power to maximize clarity and smooth playback.
    #   DC = 1 — Balanced mode reduces power usage while maintaining good playback
    #            quality, ideal for mobile viewing without excessive battery drain.
    #===============================================================================
    #>
    @{ S="9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; G="10778347-1370-4ee0-8bbd-33bdacaade49"; AC=0; DC=1 },

    <#
    #===============================================================================
    # Multimedia: video playback quality bias
    #
    # Description:
    #   Controls the system’s preference for video playback quality versus power
    #   efficiency. Quality‑biased modes prioritize sharper image rendering, higher
    #   bitrates, and smoother playback, which increases GPU usage. Balanced modes
    #   reduce GPU load while maintaining acceptable quality. Power‑saving modes
    #   minimize GPU activity, extending battery life at the cost of visual fidelity.
    #
    # Options:
    #   0 = Quality bias
    #   1 = Balanced
    #   2 = Power‑saving bias
    #
    # Recommended:
    #   AC = 0 — Ensures the highest possible video quality, taking advantage of
    #            unlimited AC power for smooth and detailed playback.
    #   DC = 1 — Balanced mode maintains good visual quality while reducing GPU
    #            power consumption, ideal for mobile viewing.
    #===============================================================================
    #>
    @{ S="9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; G="34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4"; AC=0; DC=1 },

    <#
    #===============================================================================
    # Critical battery notification
    #
    # Description:
    #   Determines whether Windows displays a warning when the battery reaches a
    #   critically low level. This notification gives the user a final chance to
    #   save work before the system performs an emergency action such as hibernation
    #   or shutdown. Disabling this notification risks sudden data loss.
    #
    # Options:
    #   0 = Disabled
    #   1 = Enabled
    #
    # Recommended:
    #   AC = 1 — Even on AC power, unexpected disconnections can occur; the warning
    #            provides essential protection against data loss.
    #   DC = 1 — Critical for preventing sudden shutdowns when battery levels drop
    #            faster than expected.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f"; AC=1; DC=1 },

    <#
    #===============================================================================
    # Critical battery action
    #
    # Description:
    #   Specifies what the system should do when the battery reaches a critically
    #   low level. Hibernate is the safest option because it preserves the session
    #   to disk and prevents data loss even if the battery fully depletes. Shutdown
    #   is faster but risks losing unsaved work. Sleep is unsafe at critical levels
    #   because the system may run out of power before resuming.
    #
    # Options:
    #   0 = Do nothing
    #   1 = Sleep
    #   2 = Hibernate
    #   3 = Shut down
    #
    # Recommended:
    #   AC = 2 — Provides maximum safety in case of unexpected AC loss or power
    #            interruptions, preserving the session reliably.
    #   DC = 2 — Prevents data loss by ensuring the system enters a non‑volatile
    #            state before the battery is fully depleted.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="637ea02f-bbcb-4015-8e2c-a1c7b9c0b546"; AC=2; DC=2 },

    <#
    #===============================================================================
    # Low battery level
    #
    # Description:
    #   Defines the battery percentage at which Windows considers the battery “low.”
    #   This threshold triggers low‑battery notifications and can initiate optional
    #   power‑saving actions. Setting this too low reduces warning time; setting it
    #   too high causes unnecessary alerts. A moderate value provides a good balance
    #   between early warning and minimal disruption.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 10 — Provides a reasonable early warning without being intrusive when
    #             the system is plugged in most of the time.
    #   DC = 15 — Gives additional buffer on battery, ensuring the user has enough
    #             time to save work or connect to power.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="8183ba9a-e910-48da-8769-14ae6dc1170a"; AC=10; DC=15 },

    <#
    #===============================================================================
    # Critical battery level
    #
    # Description:
    #   Determines the battery percentage at which the system considers the battery
    #   “critical.” At this level, Windows performs the critical battery action to
    #   prevent data loss. A value that is too low risks the system shutting down
    #   before the action can complete; too high wastes usable battery capacity.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 5 — Provides a safe threshold while maximizing usable battery capacity.
    #   DC = 5 — Ensures the system has enough time to enter hibernation before the
    #            battery is fully depleted.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469"; AC=5; DC=5 },

    <#
    #===============================================================================
    # Low battery notification
    #
    # Description:
    #   Controls whether Windows alerts the user when the battery reaches the “low”
    #   threshold. This early warning is important because it gives the user time to
    #   save work, reduce power usage, or connect the device to a charger. Disabling
    #   this notification removes an important safety net and increases the risk of
    #   unexpected shutdowns, especially during mobile use.
    #
    # Options:
    #   0 = Disabled
    #   1 = Enabled
    #
    # Recommended:
    #   AC = 1 — Even when plugged in, accidental disconnections or loose adapters
    #            can cause the battery to drain unexpectedly; the warning prevents
    #            surprise power loss.
    #   DC = 1 — Essential for mobile use, ensuring the user receives timely alerts
    #            before the system reaches critical levels.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="bcded951-187b-4d05-bccc-f7e51960c258"; AC=1; DC=1 },

    <#
    #===============================================================================
    # Low battery action
    #
    # Description:
    #   Determines what the system should do when the battery reaches the “low”
    #   threshold. Unlike the critical battery action, this is a gentler response
    #   intended to encourage the user to take action without forcing a full system
    #   state change. Sleep is a reasonable compromise: it conserves power while
    #   preserving the session, but still allows quick resume.
    #
    # Options:
    #   0 = Do nothing
    #   1 = Sleep
    #   2 = Hibernate
    #   3 = Shut down
    #
    # Recommended:
    #   AC = 0 — On AC power, low battery events are rare and usually caused by
    #            accidental unplugging; no automatic action is needed.
    #   DC = 1 — Sleep provides a gentle safeguard that prevents excessive battery
    #            drain while giving the user time to reconnect to power.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="d8742dcb-3e6a-4b3c-b3fe-374623cdcf06"; AC=0; DC=1 },

    <#
    #===============================================================================
    # Reserve battery level
    #
    # Description:
    #   Defines the battery percentage that Windows treats as a “reserve” buffer.
    #   When the battery falls below this level, Windows may take additional steps
    #   to conserve power and extend remaining runtime. This reserve helps prevent
    #   sudden shutdowns caused by battery wear, inaccurate charge reporting, or
    #   rapid discharge under heavy load.
    #
    # Options:
    #   Continuous range: 0–100 percent
    #
    # Recommended:
    #   AC = 5–7  — Provides a small but useful buffer without interfering with
    #               normal operation when the device is plugged in.
    #   DC = 7–10 — Offers extra protection during mobile use, accounting for
    #               battery aging and unpredictable discharge behavior.
    #===============================================================================
    #>
    @{ S="e73a048d-bf27-4f12-9731-8b2076e8891f"; G="f3c5027d-cd16-4930-aa6b-90db844a8f00"; AC=7; DC=10 }

)

$appliedCount = 0
$targetPlanGuid = "57696e68-616e-6365-506f-776572000000"
foreach ($setting in $settings) {
    try {
        powercfg /setacvalueindex $targetPlanGuid $setting.S $setting.G $setting.AC 2>$null
        if ($LASTEXITCODE -eq 0) {
            powercfg /setdcvalueindex $targetPlanGuid $setting.S $setting.G $setting.DC 2>$null
            if ($LASTEXITCODE -eq 0) {
                $appliedCount++
            }
        }
    } catch {
    }
}
Write-Output "Applied $appliedCount power settings"

Write-Output "Activating power plan..."
powercfg /setactive 57696e68-616e-6365-506f-776572000000 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Output "Power plan activated successfully"
} else {
    Write-Output "Failed to activate power plan"
}

$entries = @(
    @{
        Path = "HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Power"
        Name = "HiberbootEnabled"
        Type = "DWord"
        Value = 0
        Description = "Disables Fast Startup by preventing Windows from using a hibernated system state during shutdown."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings"
        Name = "ShowHibernateOption"
        Type = "DWord"
        Value = 1
        Description = "Enables the Hibernate option in the Start Menu power flyout."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        Name = "PowerThrottlingOff"
        Type = "DWord"
        Value = 1
        Description = "Disables power throttling to prevent Windows from reducing CPU performance for background processes."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings"
        Name = "ShowLockOption"
        Type = "DWord"
        Value = 1
        Description = "Enables the Lock option in the Start Menu power flyout."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings"
        Name = "ShowSleepOption"
        Type = "DWord"
        Value = 1
        Description = "Enables the Sleep option in the Start Menu power flyout."
    }
)
Apply-RegistryBatch $entries