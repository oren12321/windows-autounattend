$SecurityAndPrivacyEntries = @(
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "ContentDeliveryAllowed"
        Type        = "DWord"
        Value       = 0
        Description = "Disable content delivery features"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "FeatureManagementEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable content delivery features"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "OEMPreInstalledAppsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable OEM preinstalled apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "PreInstalledAppsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable preinstalled apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "PreInstalledAppsEverEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable preinstalled apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SilentInstalledAppsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable silent app installs"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SoftLandingEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable soft landing suggestions"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContentEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-310093Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-338387Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-338388Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-338389Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-338393Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-353694Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-353696Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-353698Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable subscribed content"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-310093Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Show what's new and suggested after updates and when signed in"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
        Name        = "ScoobeSystemSettingEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Show suggestions to help you complete device setup and optimize Windows features"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-338389Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Show helpful tips and suggestions while using Windows"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SystemPaneSuggestionsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Display helpful suggestions in the Action Center and Notification Center"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        Name        = "ShowGlobalPrompts"
        Type        = "DWord"
        Value       = 1
        Description = "Show notifications when apps attempt to access your location information"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"
        Name        = "Enabled"
        Type        = "DWord"
        Value       = 1
        Description = "Show notifications from the Security and Maintenance Action Center"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "ContentDeliveryAllowed"
        Type        = "DWord"
        Value       = 0
        Description = "Allows Windows to deliver promotional content and automatically install suggested apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContentEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Enables promotional content subscriptions from Microsoft and partners throughout Windows"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "FeatureManagementEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Enables Windows feature management functionality for promotional features and automatic app installations"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SoftLandingEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Displays tips and notifications about Windows features as you use the operating system"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "OEMPreInstalledAppsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Prevents OEM manufacturers from automatically installing bloatware apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "PreInstalledAppsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Prevents Microsoft from automatically installing suggested apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "PreInstalledAppsEverEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disables tracking of whether pre-installed apps were ever enabled"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SilentInstalledAppsEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Prevents apps from being silently installed in the background"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "RotatingLockScreenEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Displays rotating Windows Spotlight images on your lock screen instead of a static background"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "RotatingLockScreenOverlayEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Displays fun facts, tips, and tricks as an overlay on your lock screen"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SlideshowEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Enables slideshow option for lock screen background"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        Name        = "Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Windows generates a unique advertising ID that apps use to track your activity and deliver personalized ads based on your behavior across different apps"
    },
    @{
        Path        = "HKCU:\Control Panel\International\User Profile"
        Name        = "HttpAcceptLanguageOptOut"
        Type        = "DWord"
        Value       = 1
        Description = "Allows websites to access your language preferences so they can automatically display content in your preferred language without requiring manual configuration on each site"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-338393Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Microsoft displays promotional content, tips, and feature suggestions within the Windows Settings app to help you discover new features and functionality"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-353694Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Microsoft displays promotional content, tips, and feature suggestions within the Windows Settings app to help you discover new features and functionality"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name        = "SubscribedContent-353696Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Microsoft displays promotional content, tips, and feature suggestions within the Windows Settings app to help you discover new features and functionality"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications"
        Name        = "EnableAccountNotifications"
        Type        = "DWord"
        Value       = 0
        Description = "Shows account notifications in the Settings app, including prompts to reauthenticate, backup your device, and manage subscriptions"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
        Name        = "HasAccepted"
        Type        = "DWord"
        Value       = 0
        Description = "Use your voice for apps using Microsoft's online speech recognition technology"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Narrator\NoRoam"
        Name        = "OnlineServicesEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Narrator to use Microsoft cloud services for features like intelligent image descriptions and enhanced voice models"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Narrator\NoRoam"
        Name        = "ScriptingEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Narrator to execute scripts for automation and custom functionality"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization"
        Name        = "Value"
        Type        = "DWord"
        Value       = 0
        Description = "Uses your typing history and handwriting patterns to create a custom dictionary (turning off will clear all words in your custom dictionary)"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Personalization\Settings"
        Name        = "AcceptedPrivacyPolicy"
        Type        = "DWord"
        Value       = 0
        Description = "Uses your typing history and handwriting patterns to create a custom dictionary (turning off will clear all words in your custom dictionary)"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"
        Name        = "HarvestContacts"
        Type        = "DWord"
        Value       = 0
        Description = "Uses your typing history and handwriting patterns to create a custom dictionary (turning off will clear all words in your custom dictionary)"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack"
        Name        = "ShowedToastAtLevel"
        Type        = "DWord"
        Value       = 1
        Description = "Send diagnostic data to Microsoft to help improve Windows and keep it secure"
    },
    @{
        Path        = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        Name        = "AllowTelemetry"
        Type        = "DWord"
        Value       = 1
        Description = "Send diagnostic data to Microsoft to help improve Windows and keep it secure"
    },
    @{
        Path        = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        Name        = "MaxTelemetryAllowed"
        Type        = "DWord"
        Value       = 1
        Description = "Send diagnostic data to Microsoft to help improve Windows and keep it secure"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Input\TIPC"
        Name        = "Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Send optional inking and typing diagnostic data to Microsoft"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store\ImproveInkingAndTyping"
        Name        = "Value"
        Type        = "DWord"
        Value       = 0
        Description = "Send optional inking and typing diagnostic data to Microsoft"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"
        Name        = "TailoredExperiencesWithDiagnosticDataEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Let Microsoft use your diagnostic data to show personalized tips, ads and recommendations"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
        Name        = "IsDeviceSearchHistoryEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Improves search results by allowing Windows Search to store your search history locally on this device (Does not clear existing history)"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
        Name        = "IsDynamicSearchBoxEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "See content suggestions in search"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
        Name        = "IsMSACloudSearchEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Windows Search to show results from apps and services that you are signed in to with your Microsoft account"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
        Name        = "IsAADCloudSearchEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Windows Search to show results from apps and services that you are signed in to with your work or school account"
    }
)