# Expand File elements of an XML.
# PAY ATTENTION:
#     If OutputFolder is not give, Files are being expanded according
#     to the path property of the element, whcih means that they might
#     be extracted to multiple undesired palces in your PC.
#     Use carefully, or even better in a separated environmet
#     such a VM.

# or to one of your choice.
# The File element should be of the following shpae:
#     <unattend>
#       <Extensions>
#         <File path="..."> ... </File>
#         <File path="..."> ... </File>
#         ...
#         <File path="..."> ... </File>
#       </Extensions>
#     </unattend>

param(
    [string]$XmlPath,
    [string]$OutputFolder # All expanded files will be under this folder
)

. "$PSScriptRoot\Expand-EmbeddedFiles.ps1"

$xml = [xml]::new()
$xml.Load($XmlPath)

Expand-EmbeddedFiles -Document $xml -RedirectFolder $OutputFolder