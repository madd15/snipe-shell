Import-Module .\psfont.psm1
Set-ConsoleFont 11


## IIS Web Platform Installer Variables ##
if (Is64Bit) {
    $php = "PHP71x64"
    $winCache = "WinCache70x64"
    $WPI = "http://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi"
}
else {
    $php = "PHP71"
    $winCache = "WinCache70x86"
    $WPI = "http://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_x86_en-US.msi"
}

$phpMan = "PHPManager"

##################################### FUNCTIONS ##########################################################################################
function title {
	Write-Host "`n*************************************************" -Foreground Red
	Write-Host "*`t`tSnipe-IT Installation`t`t*" -Foreground Red
	Write-Host "*`t`tInstaller By Madd15`t`t*" -Foreground Red
	Write-Host "*************************************************" -Foreground Red
}
function Read-Choice {
    Param(
        [System.String]$Message,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]$Choices,
        [System.Int32]$DefaultChoice=1,
        [System.String]$Title=[string]::Empty
    )
    [System.Management.Automation.Host.ChoiceDescription[]]$Poss=$Choices | ForEach-Object {
        New-Object System.Management.Automation.Host.ChoiceDescription "&$($_)", "Sets $_ as an answer."
    }
    $Host.UI.PromptForChoice($Title, $Message, $Poss, $DefaultChoice)
}
function Expand-ZIPFile($file, $destination) {
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}
function Is64Bit {  
	[IntPtr]::Size -eq 8  
}
function installWPI ($prod, $Language) {
    $InstallManager = New-Object Microsoft.Web.PlatformInstaller.InstallManager
    $installer = New-Object 'System.Collections.Generic.List[Microsoft.Web.PlatformInstaller.Installer]'
    $installerToUse = $prod.GetInstaller($Language)
    $installer.Add($installerToUse)
    $InstallManager.load($installer)
    $failureReason=$null
    foreach ($installerContext in $InstallManager.InstallerContexts) {
        $InstallManager.DownloadInstallerFile($installerContext, [ref]$failureReason)
    }
    $InstallManager.StartInstallation()
}

#####################################
Clear-Host
title

## Download Web Platform Installer ##
Write-Output "Downloading $WPI"
$start_time = Get-Date
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($WPI, "$PSScriptRoot\wpi.msi")
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "Installing Web Platform Installer"
msiexec.exe /i '$PSScriptRoot\wpi.msi' /passive

try {
    ## Load Web Platform Installer
    [reflection.assembly]::LoadWithPartialName("Microsoft.Web.PlatformInstaller") | Out-Null
    $ProductManager = New-Object Microsoft.Web.PlatformInstaller.ProductManager
    $ProductManager.Load()
    $Language = $ProductManager.GetLanguage("en")

    try {
        ## Install PHP via WPI
        $productPHP = $ProductManager.Products | Where { $_.ProductId -eq $php }
        installWPI($productPHP, $Language)
     }
     catch {
        Write-Host "Unable to load Web Platform Installer" -ForegroundColor Red
     }
}
catch {
    Write-Host "Unable to load Web Platform Installer" -ForegroundColor Red
}

