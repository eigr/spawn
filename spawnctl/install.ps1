# Determine the correct binary name for Windows
$FILENAME = "spawnctl_windows.exe"

# Check if Spawn is already installed and run maintenance uninstall
if (Get-Command spawn -ErrorAction SilentlyContinue) {
    Write-Host "Previous version of Spawn CLI detected. Running 'spawn maintenance uninstall' to remove cached files."
    spawn maintenance uninstall
}

# Download the binary
$URL = "https://github.com/eigr/spawn/releases/download/v2.0.0-RC9/$FILENAME"
$DOWNLOAD_PATH = "$env:TEMP\spawn.exe"

Invoke-WebRequest -Uri $URL -OutFile $DOWNLOAD_PATH

# Rename and move the binary to a directory in the user's PATH
$DESTINATION = "$env:USERPROFILE\spawn\spawn.exe"
New-Item -ItemType Directory -Force -Path (Split-Path $DESTINATION)
Move-Item -Path $DOWNLOAD_PATH -Destination $DESTINATION -Force

# Add the directory to the PATH if not already present
$PROFILE_PATH = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (!(Test-Path $PROFILE_PATH)) {
    New-Item -ItemType File -Path $PROFILE_PATH -Force
}

if (-not ($env:Path -like "*$($DESTINATION | Split-Path)*")) {
    Add-Content -Path $PROFILE_PATH -Value "`n`$env:Path += `";$($DESTINATION | Split-Path)`""
    Write-Host "Added Spawn CLI to your PATH. Please restart your terminal or run `& `$PROFILE_PATH` to reload your profile."
} else {
    Write-Host "Spawn CLI is already in your PATH."
}

Write-Host "Spawn CLI has been installed successfully! You can now use it by typing 'spawn' in your terminal."
