. "$PSScriptRoot\Apply-Registry.ps1"

$entries = @(
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        Name = "TurnOffWindowsCopilot"
        Type = "DWord"
        Value = 1
        Description = "Disables the Windows Copilot feature for the system."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        Name = "DisableAIDataAnalysis"
        Type = "DWord"
        Value = 1
        Description = "Prevents Windows AI components from analyzing user data."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        Name = "DisableAIRecall"
        Type = "DWord"
        Value = 1
        Description = "Disables the Windows Recall feature in Windows AI."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        Name = "DisableSuggestions"
        Type = "DWord"
        Value = 1
        Description = "Turns off Suggested Actions within the Windows system UI."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
        Name = "AllowNewsAndInterests"
        Type = "DWord"
        Value = 0
        Description = "Disables the News and Interests widget on the taskbar."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
        Name = "EnableFeeds"
        Type = "DWord"
        Value = 0
        Description = "Disables Windows Feeds and related widget content."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Name = "DisableSearchBoxSuggestions"
        Type = "DWord"
        Value = 1
        Description = "Disables AI-powered search box suggestions in Windows Search."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        Name = "DisableSearchBoxSuggestions"
        Type = "DWord"
        Value = 1
        Description = "Disables Bing search box suggestions in Start Menu Search."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Name = "ConnectedSearchUseWeb"
        Type = "DWord"
        Value = 0
        Description = "Prevents Windows Search from using web-based results."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Name = "AllowSearchToUseLocation"
        Type = "DWord"
        Value = 0
        Description = "Blocks Windows Search from accessing the device's location."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        Name = "HideRecommendedSection"
        Type = "DWord"
        Value = 1
        Description = "Hides the Recommended section in the Start Menu."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        Name = "DisableTailoredExperiencesWithDiagnosticData"
        Type = "DWord"
        Value = 1
        Description = "Disables personalized experiences based on diagnostic data."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        Name = "DisableConsumerFeatures"
        Type = "DWord"
        Value = 1
        Description = "Disables consumer-focused cloud content and features."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"
        Name = "AllowInputPersonalization"
        Type = "DWord"
        Value = 0
        Description = "Prevents Windows from personalizing typing and input behavior."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"
        Name = "RestrictImplicitTextCollection"
        Type = "DWord"
        Value = 1
        Description = "Blocks Windows from collecting text input for AI learning."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"
        Name = "RestrictImplicitInkCollection"
        Type = "DWord"
        Value = 1
        Description = "Blocks Windows from collecting handwriting input for AI learning."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
        Name = "DisableStoreApps"
        Type = "DWord"
        Value = 1
        Description = "Prevents the Microsoft Store from updating system components."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
        Name = "AllowWebExperiencePackUpdates"
        Type = "DWord"
        Value = 0
        Description = "Blocks updates to the Web Experience Pack, including widget and Copilot components."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        Name = "DisableOnlineContent"
        Type = "DWord"
        Value = 1
        Description = "Disables Online Service Experience Packs and cloud-delivered content."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
        Name = "LetAppsRunAI"
        Type = "DWord"
        Value = 0
        Description = "Prevents inbox apps from using AI-powered preview features."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        Name = "DisableWindowsSpotlightFeatures"
        Type = "DWord"
        Value = 1
        Description = "Disables Windows Spotlight and its AI-driven content recommendations."
    }
)
Apply-RegistryBatch $entries
