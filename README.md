# Microsoft365SortGooglePhotos
Sorts a Google Photos data export from takeout.google.com for Microsoft OneDrive.

## Usage

```PowerShell
.\Main.ps1 -ExportZip "takeout.zip" -ExtractDirectory "GooglePhotos" -OneDriveDirectory "OneDrivePhotos" -Verbose

# Or, use the command below to clean up the $ExtractDirectory once completed.
.\Main.ps1 -ExportZip "takeout.zip" -ExtractDirectory "GooglePhotos" -OneDriveDirectory "OneDrivePhotos" -Cleanup
```

The script will create the following example directory structure:

**NOTE: As of 14th June 2020, this is the directory structure created by the OneDrive IOS app when using camera roll auto upload.**

```
OneDrivePhotos
└── Pictures
    └── Camera Roll
        ├── 2008
        │   └── 01
        ├── 2012
        │   ├── 07
        │   └── 10
        ├── 2013
        │   └── 02
        ├── 2014
        │   ├── 02
        │   ├── 04
        │   ├── 07
        │   └── 10
        ├── 2015
        │   ├── 09
        │   ├── 10
        │   ├── 11
        │   └── 12
```

## Important Information

When creating your Google Photos data export, ensure to **NOT** include albums. 
From my investigation I found that all of the photos and videos included in the albums were also included in their respective year-month-day directory in the export.

By all means, check for yourself ;-) If this has changed, submit an issue :-)

## Authors -- Contributors

* **Dextroz** - *Author* - [Dextroz](https://github.com/Dextroz)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) for details.