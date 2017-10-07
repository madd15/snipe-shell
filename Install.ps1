Import-Module .\psfont.psm1
Import-Module .\functions.psm1
Set-ConsoleFont 11


## IIS Web Platform Installer Variables ##
if (Is64Bit) {
    $php = "PHP71x64"
    $winCache = "WinCache70x64"
    $WPI = "https://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi"
}
else {
    $php = "PHP71"
    $winCache = "WinCache70x86"
    $WPI = "https://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_x86_en-US.msi"
}

$phpMan = "PHPManager"

#####################################
Clear-Host
title

## Download Web Platform Installer ##
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($WPI, "wpi.msi")
msiexec.exe /i wpi.msi /passive

try {
    [reflection.assembly]::LoadWithPartialName("Microsoft.Web.PlatformInstaller") | Out-Null
    Write-Host('Done')
}
catch {
    Write-Host('error')
}