<#
.SYNOPSIS
    A script to sort Google Photos takeout export data.

.DESCRIPTION
    A script to sort Google Photos export data into the directory file structure created by OneDrive when auto uploading images and videos.

.PARAMETER ExportZip
    The PATH on the machine to the Google Photos takeout ZIP file.

.PARAMETER ExtractDirectory
    The PATH on the system to extract the Google Photos takeout ZIP file.

.EXAMPLE
    Main.ps1 -ExportZip "takeout.zip" -ExtractDirectory "onedrivephotos" -Verbose

.NOTES
    Ensure your Google Photos takeout export doesn't contains albums.
    You don't need to export them as the photos and videos in the albums are included in their respective year-month-day directory.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $ExportZip,

    [Parameter(Mandatory = $true)]
    [String]
    $ExtractDirectory
)
$Version = "0.0.1"
# Begin logging
Write-Output -InputObject "Creating logfile."
Start-Transcript -Path "$(Get-Date -Format 'dd-MM-yyy-HH-mm-ss')-Log" -Force -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"

# Expand zip file
Write-Output -InputObject "Extracting Google Photos ZIP file: $ExportZip to directory: $ExtractDirectory."
try {
    Write-Verbose -Message "Attempting to create directory: $($ExtractDirectory) to expand ZIP file into."
    if (-not (Test-Path -Path $ExtractDirectory)) {
        Write-Verbose -Message "Creating directory: $ExtractDirectory."
        New-Item -Path $ExtractDirectory -ItemType "Directory" -Force -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
    }
    Write-Verbose -Message "Attempting to expand Google Photos ZIP file."
    Expand-Archive -Path $ExportZip -DestinationPath $ExtractDirectory -Force -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
}
catch {
    Write-Error -Message "Failed to expand Google Photos ZIP file: $($ExportZip): $($_.Exception.Message)."
    break
}
# Collect directory names
try {
    Write-Verbose -Message "Collecting directory names."
    # The directory containing the Year-Month-Day directories containing photos
    $MainDirectory = "$ExtractDirectory/Takeout/Google Photos"
    $DateDirs = Get-ChildItem -Path $MainDirectory -Directory -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
}
catch {
    Write-Error -Message "Failed to obtain directories in path:  $($_.Exception.Message)."
    break
}

<#
OneDrive directory structure for images and videos via app auto upload. Re-create this
Pictures
	Camera Roll
		2020
			01
			02
			xx
			12
#>
# Create directory structure for Onedrive
$OneDriveTopLevelDirectory = "$MainDirectory/Pictures/Camera Roll"
try {
    Write-Verbose -Message "Attempting to create top level directory structure for OneDrive."
    New-Item -Path $OneDriveTopLevelDirectory -ItemType "Directory" -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
}
catch {
    Write-Error -Message "Failed to create top level directory structure for OneDrive with path: $($MainDirectory): $($_.Exception.Message)."
    break
}
# Iterate over directories in Google Photos export. Move them into the appropriate directory based on year and month
foreach ($DateDir in $DateDirs) {
    Write-Verbose -Message "Processing directory: $($DateDir.Name)."
    # Obtain directory year
    $DirectoryYear = ($DateDir.Name -split "-")[0]
    # Obtain directory month
    $DirectoryMonth = ($DateDir.Name -split "-")[1]
    Write-Verbose -Message "Directory year: $DirectoryYear, month: $DirectoryMonth."
    
    # Create year and month directory if not present
    $DirectoryFullDate = "$OneDriveTopLevelDirectory/$DirectoryYear/$DirectoryMonth"
    if (-not (Test-Path -Path $DirectoryFullDate)) {
        Write-Verbose -Message "Directory: $DirectoryFullDate not found. Attempting to create it..."
        try {
            New-Item -Path $DirectoryFullDate -ItemType "Directory" -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
        }
        catch {
            Write-Error -Message "Failed to create directory: $($DirectoryFullDate): $($_.Exception.Message)."
            break 
        }
    }
    else {
        Write-Verbose -Message "Directory: $DirectoryFullDate already exists."
    }
    # Obtain all photos and video in the directory
    Write-Verbose -Message "Attempting to obtain all photos and videos in directory: $($DateDir.Name)."
    $PhotosAndVideos = $DateDir | Get-ChildItem -Exclude "*.json" -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
    # For every photo and video retrieved, copy them to the correct directory
    $PhotosAndVideos | ForEach-Object -Process { 
        Write-Verbose -Message "Copying item: $($_.FullName) to directory: $DirectoryFullDate."
        Copy-Item -Path $_.FullName -Destination $DirectoryFullDate -Force -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop" }
}

# End logging
Stop-Transcript
