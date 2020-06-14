<#
.SYNOPSIS
    Sorts a Google Photos data export from takeout.google.com for Microsoft OneDrive.

.DESCRIPTION
    A script to sort a Google Photos data export from takeout.google.com into the directory file structure created by OneDrive when auto uploading images and videos.

.PARAMETER ExportZip
    The PATH on the machine to the Google Photos data export ZIP file.

.PARAMETER ExtractDirectory
    The PATH on the system to extract the Google Photos data export ZIP file.

.PARAMETER OneDriveDirectory
    The PATH on the system to create the OneDrive directory structure containing the Google Photos data export photos and videos.

.PARAMETER Cleanup
    Delete the ExtractDirectory once finished.

.EXAMPLE
    Main.ps1 -ExportZip "takeout.zip" -ExtractDirectory "GooglePhotos" -OneDriveDirectory "OneDrivePhotos" -Verbose

.EXAMPLE
    Main.ps1 -ExportZip "takeout.zip" -ExtractDirectory "GooglePhotos" -OneDriveDirectory "OneDrivePhotos" -Cleanup

.NOTES
    Ensure your Google Photos data export does **NOT** contains albums.
    You don't need to export albums as the photos and videos in them are also included in their respective year-month-day directory within the export.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    [ValidateScript({
        # Check parameter provided is a file
        if (-not (Test-Path -Path $_ -PathType "Leaf")) {
            Write-Error -Message "Provided parameter: $_ is not a file." -ErrorAction "Stop"
        }
        # Check provided file ends with .zip extension
        if ($_ -notlike "*.zip") {
            Write-Error -Message "Provided parameter: $_ is not a zip file." -ErrorAction "Stop"
        }
        return $true
    })]
    [ValidateNotNullOrEmpty()]
    $ExportZip,

    [Parameter(Mandatory = $true)]
    [String]
    [ValidateNotNullOrEmpty()]
    $ExtractDirectory,

    [Parameter(Mandatory = $true)]
    [String]
    [ValidateNotNullOrEmpty()]
    $OneDriveDirectory,

    [Parameter]
    [Switch]
    $Cleanup
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
Write-Output -InputObject "Collecting directory names to create OneDrive directory structure."
try {
    # The directory containing the Year-Month-Day directories containing photos
    $MainDirectory = "$ExtractDirectory/Takeout/Google Photos"
    Write-Verbose -Message "Collecting directory names from directory: $MainDirectory."
    $DateDirs = Get-ChildItem -Path $MainDirectory -Directory -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
}
catch {
    Write-Error -Message "Failed to obtain directories in path: $($MainDirectory): $($_.Exception.Message)."
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
# Create directory structure for OneDrive
$OneDriveTopLevelDirectory = "$OneDriveDirectory/Pictures/Camera Roll"
Write-Output -InputObject "Creating required OneDrive top level directories in path: $OneDriveTopLevelDirectory."
try {
    Write-Verbose -Message "Attempting to create top level directory structure for OneDrive."
    New-Item -Path $OneDriveTopLevelDirectory -ItemType "Directory" -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
}
catch {
    Write-Error -Message "Failed to create top level directory structure for OneDrive with path: $($OneDriveTopLevelDirectory): $($_.Exception.Message)."
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
    try {
        Write-Verbose -Message "Attempting to obtain all photos and videos in directory: $($DateDir.Name)."
        $PhotosAndVideos = $DateDir | Get-ChildItem -Exclude "*.json" -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
    }
    catch {
        Write-Error -Message "Failed to obtain all photos and videos in directory: $($DateDir.Name): $($_.Exception.Message)."
        break
    }
    # For every photo and video retrieved, copy them to the correct directory
    Write-Output -InputObject "Copying photos and videos from directory: $($DateDir.Name) to directory: $DirectoryFullDate."
    $PhotosAndVideos | ForEach-Object -Process { 
        Write-Verbose -Message "Copying item: $($_.FullName) to directory: $DirectoryFullDate."
        Copy-Item -Path $_.FullName -Destination $DirectoryFullDate -Force -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop" }
}

if ($Cleanup) {
    Write-Output -InputObject "Cleaning up..."
    try {
        Write-Verbose -Message "Attempting to recursively cleanup (delete) directory: $ExtractDirectory."
        Remove-Item -Path $ExtractDirectory -Recurse -Force -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
    }
    catch {
        Write-Error -Message "Failed to cleanup (delete) directory: $($ExtractDirectory): $($_.Exception.Message)."
        break
    }
}

# End logging
Stop-Transcript
