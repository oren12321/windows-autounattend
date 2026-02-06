@{
    Version = "1.0.0"
    
    # Internal: Folders within this project tree (No 'Shared' folder created)
    SubProjects = @(
        "src/Core",
        "src/Ui"
    )
    
    # External: Projects or Assets to be inlined (Creates 'Shared' folder)
    Dependencies = @(
        "../External/CommonLib",           # Standard Project
        "../Assets/logo.png",              # Static File
        @{ Name="Net"; Path="../Network" } # Aliased Project
    )
}
