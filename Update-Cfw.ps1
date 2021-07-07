[Flags()] enum MainMenuFlags {
    NO_SELECTION = 0
    UPDATE_ATMOSPHERE = 1
    UPDATE_HEKATE = 2
}

[Flags()] enum ConfigMenuFlags {
    NO_SELECTION = 0
    KEEP_SYSMODULES = 1
    KEEP_AMS_CONFIGS = 2
    UPDATE_REBOOT_PAYLOAD = 4
    FRESH_INSTALL = 256
}

function IIf($If, $IfTrue, $IfFalse) {
    if ($If) {if ($IfTrue -is "ScriptBlock") {&$IfTrue} else {$IfTrue}}
    else {if ($IfFalse -is "ScriptBlock") {&$IfFalse} else {$IfFalse}}
}

function Get-FormattedText ($Text, $MaxLength=80) {
    $AllWords = $Text -split " "
    
    $Lines = @()
    $LineWords = @()

    $MaxWordLength = $MaxLength - 8 # Padding characters

    while($AllWords.Count -gt 0) {
        $Word, [array]$AllWords = $AllWords
        if($null -eq $AllWords) {
            $AllWords = @()
        }

        $TestWordLength = (($LineWords + $Word) -join " ").Length
        if($TestWordLength -gt $MaxWordLength) {
            $Line = $LineWords -join " "
            $Lines = $Lines + $Line
            $LineWords = @()
            $AllWords = @($Word) + $AllWords
        }
        else {
            $LineWords = $LineWords + $Word
        }
    }

    if($LineWords.Count -gt 0) {
        $Lines += ($LineWords -join " ")
    }

    $Lines | ForEach-Object {
        $PadLeft = [int](($MaxWordLength - $_.Length)/2) + $_.Length
        "#   {0}   #" -f ($_.PadLeft($PadLeft).PadRight($MaxWordLength))
    }
}

$TextBar = "#" * 80

$TopBar = & {
$TextBar
$TextBar
Get-FormattedText ""
Get-FormattedText "SWITCH CFW UPDATER"
Get-FormattedText ""
$TextBar
$TextBar
Get-FormattedText "This tool will update Atmosphere and Hekate on your Switch SD card.  It also provides options that allow you to keep configuration files, homebrew apps, etc."
Get-FormattedText ""
Get-FormattedText "https://www.github.com/cpurules/ps-cfw-updater"
$TextBar
""
}

function Generate-MainMenuSelections($MainMenuFlags, $FailMessage) {
    if($null -ne $FailMessage) {
        "Invalid menu selection: $FailMessage"
        ""
    }
    "Please choose which CFW components you would like to update."
    "[{0}]  Update [A]tmosphere" -f (IIf ($MainMenuFlags -band [MainMenuFlags]::UPDATE_ATMOSPHERE) "X" " ")
    "[{0}]  Update [H]ekate" -f (IIF ($MainMenuFlags -band [MainMenuFlags]::UPDATE_HEKATE) "X" " ")
    ""
    "Enter the corresponding letter to toggle updates."
    "Enter 'c' to continue, or 'q' to quit."
}

[MainMenuFlags]$MainMenuFlags = 0
$MainMenuLoop = $true
$FailMessage = $null
while($MainMenuLoop) {
    Clear-Host
    $TopBar
    Generate-MainMenuSelections $MainMenuFlags $FailMessage

    $Selection = Read-Host

    if($Selection -eq 'q') {
        return
    }
    elseif($Selection -eq 'c') {
        if($MainMenuFlags -eq 0) {
            $FailMessage = "You have to pick at least one CFW component to update."
        }
        else {
            $MainMenuLoop = $false
        }
    }
    elseif($Selection -eq 'a') {
        $MainMenuFlags = $MainMenuFlags -bxor [MainMenuFlags]::UPDATE_ATMOSPHERE
    }
    elseif($Selection -eq 'h') {
        $MainMenuFlags = $MainMenuFlags -bxor [MainMenuFlags]::UPDATE_HEKATE
    }
    else {
        $FailMessage = "I don't recognize '$Selection'"
    }
}

function Generate-ConfigMenuSelections($MainMenuFlags, $ConfigMenuFlags, $FailMessage) {
    if($null -ne $FailMessage) {
        "Invalid menu selection: $FailMessage"
        ""
    }
    "Below you will see options available for the component(s) you selected."
    if($MainMenuFlags -band [MainMenuFlags]::UPDATE_ATMOSPHERE) {
        "[{0}]  Keep [m]odules (sys-botbase, sys-ftpd, etc.)" -f (IIf ($ConfigMenuFlags -band [ConfigMenuFlags]::KEEP_SYSMODULES) "X" " ")
        "[{0}]  Keep [A]tmosphere config folder" -f (IIf ($ConfigMenuFlags -band [ConfigMenuFlags]::KEEP_AMS_CONFIGS) "X" " ")
    }
    if($MainMenuFlags -band [MainMenuFlags]::UPDATE_HEKATE) {
        "[{0}]  Update [r]eboot_payload.bin" -f (IIF ($ConfigMenuFlags -band [ConfigMenuFlags]::UPDATE_REBOOT_PAYLOAD) "X" " ")
    }
    "[{0}]  [F]resh install - keep nothing" -f (IIf ($ConfigMenuFlags -band [ConfigMenuFlags]::FRESH_INSTALL) "X" " ")

    ""
    "Enter the corresponding letter to toggle the setting."
    "Enter 'c' to continue, or 'q' to quit."
}

[ConfigMenuFlags]$ConfigMenuFlags = 7 # All turned on except fresh install by default
$ConfigMenuLoop = $true
$FailMessage = $null
while($ConfigMenuLoop) {
    Clear-Host
    $TopBar
    Generate-ConfigMenuSelections $MainMenuFlags $ConfigMenuFlags $FailMessage
    
    $Selection = Read-Host

    if($Selection -eq 'q') {
        return
    }
    elseif($Selection -eq 'c') {
        $ConfigMenuLoop = $false
    }
    elseif($Selection -eq 'm') {
        $ConfigMenuFlags = $ConfigMenuFlags -bxor [ConfigMenuFlags]::KEEP_SYSMODULES
        $ConfigMenuFlags = $ConfigMenuFlags -band (-bnot [ConfigMenuFlags]::FRESH_INSTALL)
    }
    elseif($Selection -eq 'a') {
        $ConfigMenuFlags = $ConfigMenuFlags -bxor [ConfigMenuFlags]::KEEP_AMS_CONFIGS
        $ConfigMenuFlags = $ConfigMenuFlags -band (-bnot [ConfigMenuFlags]::FRESH_INSTALL)
    }
    elseif($Selection -eq 'r') {
        $ConfigMenuFlags = $ConfigMenuFlags -bxor [ConfigMenuFlags]::UPDATE_REBOOT_PAYLOAD
        $ConfigMenuFlags = $ConfigMenuFlags -band (-bnot [ConfigMenuFlags]::FRESH_INSTALL)
    }
    elseif($Selection -eq 'f') {
        $ConfigMenuFlags = [ConfigMenuFlags]::FRESH_INSTALL
    }
    else {
        $FailMessage = "I don't recognize '$Selection'"
    }
}

$DriveMenuLoop = $true
$FailMessage = $null
while($DriveMenuLoop) {
    Clear-Host
    $TopBar
    if($null -ne $FailMessage) {
        "Invalid entry: $FailMessage"
        ""
    }
    "Please enter the path to the root of your SD card."
    "If you are on Windows, this will simply be the drive, e.g. D:\"
    "If you are on Linux, this will be a mount path, e.g. /mnt/sd/"
    ""
    $DrivePath = Read-Host -Prompt "Path to SD Card"
    if($DrivePath -eq "") {
        $FailMessage = "You have to enter the path to your SD card"
    }
    elseif(-not (Test-Path $DrivePath)) {
        $FailMessage = "Could not find provided path '$DrivePath'"
    }
    else {
        $DriveMenuLoop = $false
    }
}

Clear-Host
$TopBar
if($MainMenuFlags -band [MainMenuFlags]::UPDATE_ATMOSPHERE) {
    Write-Output "Beginning Atmosphere update"
    if($ConfigMenuFlags -band [ConfigMenuFlags]::FRESH_INSTALL) {
        Write-Output "Fresh install selected!  Removing the following files/directories:"
        $RemovePaths = @("switch", "sept", "atmosphere", "hbmenu.nro") | ForEach-Object { Join-Path $DrivePath $_ }
        foreach($Path in $RemovePaths) {
            Write-Output "- $Path"
            Remove-Item -Path $Path -Recurse -Force
        }
    }
    else {
        Write-Output "Cleaning up existing Atmosphere installation"
        $Exclusions = @()
        if($ConfigMenuFlags -band [ConfigMenuFlags]::KEEP_SYSMODULES) {
            Write-Output "Excluding sysmodules (/atmosphere/contents)"
            $Exclusions += "contents"
        }
        if($ConfigMenuFlags -band [ConfigMenuFlags]::KEEP_AMS_CONFIGS) {
            Write-Output "Excluding configurations (/atmosphere/config)"
            $Exclusions += "config"
        }
        $AmsToRemove = Get-ChildItem -Path (Join-Path $DrivePath "atmosphere") -Exclude $Exclusions
        $AmsToRemove | Remove-Item -Recurse -Force
        Remove-Item -Path (Join-Path $DrivePath "sept") -Recurse -Force
        Remove-Item -Path (Join-Path $DrivePath "hbmenu.nro") -Force
    }
    Write-Output "Checking for latest Atmosphere release"
    $AmsRelease = Invoke-RestMethod -Uri https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases?per_page=1
    Write-Output "Latest version: $($AmsRelease.tag_name)"
    
    $AmsFiles = $AmsRelease.assets
    $Fusee = $AmsFiles | Where-Object { $_.name -eq "fusee-primary.bin" }
    Write-Output "Downloading fusee-primary.bin to current directory..."
    Invoke-WebRequest -Uri $Fusee.browser_download_url -OutFile $Fusee.name
    
    $Ams = $AmsFiles | Where-Object { $_.name -like "atmosphere*.zip" -and $_.name -notlike "*WITHOUT_MESOSPHERE*" }
    Write-Output "Downloading $($Ams.name) to current directory"
    Invoke-WebRequest -Uri $Ams.browser_download_url -OutFile $Ams.name

    Write-Output "Extracting $($Ams.name) to current directory"
    $Dir = $Ams.name -replace "\.zip",""
    Expand-Archive -Path $($Ams.name) -DestinationPath (Join-Path $PWD $Dir) -Force

    Write-Output "Copying files to SD card"
    Get-ChildItem -Path (Join-Path $PWD $Dir) | Copy-Item -Destination $DrivePath -Recurse -Force

    Write-Output "Cleaning up local directory"
    Remove-Item -Path (Join-Path $PWD $Dir) -Recurse -Force
    Remove-Item -Path $Ams.name

    Write-Output "Atmosphere update finished!"
    Write-Output "fusee-primary.bin is here, if needed:"
    Write-Output (Join-Path $PWD "fusee-primary.bin")
    Write-Output ""
}
if($MainMenuFlags -band [MainMenuFlags]::UPDATE_HEKATE) {
    Write-Output "Beginning Hekate update"
    if($ConfigMenuFlags -band [ConfigMenuFlags]::FRESH_INSTALL) {
        Write-Output "Fresh install selected!  Removing the following files/directories:"
        $RemovePaths = @("bootloader") | ForEach-Object { Join-Path $DrivePath $_ }
        foreach($Path in $RemovePaths) {
            Write-Output "- $Path"
            Remove-Item -Path $Path -Recurse -Force
        }
    }
    Write-Output "Checking for latest Hekate release"
    $HekRelease = Invoke-RestMethod -Uri https://api.github.com/repos/CTCaer/hekate/releases?per_page=1
    Write-Output "Latest version: $($HekRelease.tag_name)"
    
    $HekFiles = $HekRelease.assets
    $Hekate = $HekFiles | Where-Object { $_.name.StartsWith("hekate_") }
    Write-Output "Downloading $($Hekate.name) to current directory..."
    Invoke-WebRequest -Uri $Hekate.browser_download_url -OutFile $Hekate.name

    Write-Output "Extracting $($Hekate.name) to current directory"
    $Dir = $Hekate.name -replace "\.zip",""
    Expand-Archive -Path $($Hekate.name) -DestinationPath (Join-Path $PWD $Dir) -Force

    Write-Output "Copying files to SD card"
    Get-Item -Path (Join-Path $PWD "$Dir\bootloader") | Copy-Item -Destination $DrivePath -Recurse -Force

    $HekateBin = Get-ChildItem -Path (Join-Path $PWD $Dir) -File | Where-Object { $_.Name -like "hekate*.bin" }
    $HekateBin = $HekateBin | Copy-Item -Destination (Split-Path $HekateBin.DirectoryName -Parent) -Force -PassThru
    if($ConfigMenuFlags -band [ConfigMenuFlags]::UPDATE_REBOOT_PAYLOAD) {
        Write-Output "Updating /atmosphere/reboot_payload.bin to Hekate .bin"
        $HekateBin | Copy-Item -Destination (Join-Path $DrivePath "atmosphere/reboot_payload.bin") -Force
    }
    
    Write-Output "Cleaning up local directory"
    Remove-Item -Path (Join-Path $PWD $Dir) -Recurse -Force
    Remove-Item -Path $Hekate.name -Force

    Write-Output "Hekate update finished!"
    Write-Output "$($HekateBin.name) is here, if needed:"
    Write-Output $HekateBin.FullName
    Write-Output ""
}
