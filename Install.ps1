Import-Module .\psfont.psm1
Set-ConsoleFont 11

$php_install = "C:\PHP"
$php_temp = "C:\php_temp"
$php_log = "C:\php_log"
$php_version = "5.6.6"
$php_url = "http://windows.php.net/downloads/releases"
$php_zip = "php-5.6.6-nts-Win32-VC11-x86.zip"
$phpmgrInstallMedia_86 = "PHPManagerForIIS-1.2.0-x86.msi /q"
$phpmgrInstallMedia_64 = "PHPManagerForIIS-1.2.0-x64.msi /q"
$phpmgr_url_86 = "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=phpmanager&DownloadId=253208&FileTime=129536821813170000&Build=20959"
$phpmgr_url_64 = "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=phpmanager&DownloadId=253209&FileTime=129536821813970000&Build=20959"

function title
{
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
function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}
}
function Is64Bit  
{  
	[IntPtr]::Size -eq 8  
}
function downloadFile($url, $targetFile)
{
    "Downloading $url"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
        [System.Console]::CursorLeft = 0
        [System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
    "`nFinished Download"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
} 

####################################################################################################################################################################
Clear-Host
title
Write-Host "`n*************************************************" -Foreground Yellow
Write-Host "*`tWould you like to setup the IIS Site`t*" -Foreground Yellow
Write-Host "*************************************************" -Foreground Yellow
$iis = Read-Host "`nConfirm (y or n)"
if($iis -eq 'y' -Or $iis -eq 'Y')
{
	$iis_service = Get-Service W3SVC
	if (!($iis_service)) {
		Add-WindowsFeature Web-Server,web-management-console
	} else
	{
		if($iis_service.status -ne "Running") {
			Start-Service W3SVC
			Write-Host "IIS - Already Installed and Now Running..." -ForegroundColor Green
		}
		if($iis_service.status -eq "Running") {
			Write-Host "IIS - Already Installedand Running..." -ForegroundColor Green
		}
	}
	if((Test-Path .\php_temp) -ne $true) {
		new-item -type directory -path .\php_temp
		Write-Host "Downloading PHP 5.6.6..."
		$client = New-Object "System.Net.WebClient"
		downloadFile $php_url.'/'.$php_zip .\
		Expand-ZIPFile -File "$php_zip" -Destination ".\php_temp"
	}
	if ((Test-Path -path $php_install) -ne $True) {
		new-item -type directory -path $php_install
		$acl = get-acl $php_install
		$ar = new-object system.security.accesscontrol.filesystemaccessrule("IIS AppPool\DefaultAppPool", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None","Allow")
		$acl.setaccessrule($ar)
		$ar = new-object system.security.accesscontrol.filesystemaccessrule("Users", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None","Allow")
		$acl.setaccessrule($ar)
		set-acl $php_install $acl

		copy-item .\php_temp -destination $php_install."\".$php_version -recurse
	} else {
		Write-Host "C:\PHP exists. Assuming that php is installed." -ForegroundColor Green;
	}
	if ((Test-Path -path $php_temp) -ne $True) {
		new-item -type directory -path $php_temp
		$acl = get-acl $php_temp
		$ar = new-object system.security.accesscontrol.filesystemaccessrule("Users","Modify","Allow")
		$acl.setaccessrule($ar)
		$ar = new-object system.security.accesscontrol.filesystemaccessrule("IIS AppPool\DefaultAppPool", "Modify", "ContainerInherit, ObjectInherit", "None","Allow")
		$acl.setaccessrule($ar)
		set-acl $php_temp $acl
	}
	if ((Test-Path -path $php_log) -ne $True) {
		new-item -type directory -path $php_log
		$acl = get-acl $php_log
		$ar = new-object system.security.accesscontrol.filesystemaccessrule("Users","Modify","Allow")
		$acl.setaccessrule($ar)
		$ar = new-object system.security.accesscontrol.filesystemaccessrule("IIS AppPool\DefaultAppPool", "Modify", "ContainerInherit, ObjectInherit", "None","Allow")
		$acl.setaccessrule($ar)
		set-acl $php_log $acl
	}
	if (Is64Bit){
		(new-object net.webclient).DownloadString($phpmgr_url_64)
		start-process "c:\windows\system32\msiexec.exe" -ArgumentList "/i $phpmgrInstallMedia_64 /q" -Wait
	}else{
		(new-object net.webclient).DownloadString($phpmgr_url_86)
		start-process "c:\windows\system32\msiexec.exe" -ArgumentList "/i $phpmgrInstallMedia_86 /q" -Wait
	}
	if ( (Get-PSSnapin -Name PHPManagerSnapin -ErrorAction SilentlyContinue) -eq $null )
	{
		Add-PsSnapin PHPManagerSnapin
	}		
	New-PHPVersion -ScriptProcessor "$php_install\$php_version\php-cgi.exe"
	Set-PHPSetting -name upload_tmp_dir -value $php_temp
	Set-phpsetting -name session.save_path -value $php_temp
	Set-PHPSetting -name error_log -value "$php_log\php-errors.log"
	function InstallIISRewriteModule(){  
	    $wc = New-Object System.Net.WebClient  
	    $dest = "IISRewrite.msi"  
	    $url  
	    if (Is64Bit){  
	        $url = "http://go.microsoft.com/?linkid=9722532"  
	    } else{  
	        $url = "http://go.microsoft.com/?linkid=9722533"       
	    }  
	    $wc.DownloadFile($url, $dest)  
	    msiexec.exe /i IISRewrite.msi /passive  
	}  
	if (!(Test-Path "$env:programfiles\Reference Assemblies\Microsoft\IIS\Microsoft.Web.Iis.Rewrite.dll")){  
	    InstallIISRewriteModule  
	} else  
	{  
	    Write-Host "IIS Rewrite Module - Already Installed..." -ForegroundColor Green  
	}
	$iis_done = 'N'
	Do {
		#Set Defaults For IIS Site
			$Identity="2"
			[string]$Runtime="v2.0"
			[string]$Pipeline="Integrated"
		#Prompt User For IIS Site Settings
			$sitename = Read-Host "`nEnter Site Name (Default: Snipe-IT)"
			$port = Read-Host "`nEnter Port (Default:80)"
			$hostname = Read-Host "`nEnter Hostname (Default:*)"
			$directory = Read-Host "`nWebsite Directory (Default: C:\inetpub\wwwroot\Snipe-IT)"
		if ($sitename -eq '') {
			$sitename = "Snipe-IT"
		}
		if ($port -eq '') {
			$port = "80"
		}
		if ($hostname -eq '') {
			$hostname = "*"
		}
		if ($directory -eq '') {
			$directory = "C:\inetpub\wwwroot\Snipe-IT"
		}
		#Echo out settings
		Write-Host "`nSite Name: "-nonewline; Write-Host "$sitename" -ForegroundColor DarkGreen
		Write-Host "Port: "-nonewline; Write-Host "$port" -ForegroundColor DarkGreen
		Write-Host "hostname: "-nonewline; Write-Host "$hostname" -ForegroundColor DarkGreen
		Write-Host "Directory: "-nonewline; Write-Host "$directory" -ForegroundColor DarkGreen
		#Create Directory
		Write-Host "Creating $sitename directory" -ForegroundColor Yellow
		$test_dir = Test-Path $directory
		if (!($test_dir)) {
			New-Item -ItemType Directory -Path $directory
			$iisdone = Read-Host "Continue"
			$iis_done = 'Y'
		} elseif ($test_dir) {
			Write-Host "Error: Folder already exists!" -ForegroundColor Red
			$iisretry = Read-Host "Retry IIS Setup?"
			$iis_done = 'N'
		}
	} while ($iis_done -eq 'N')

	# Creates the website logfiles directory
	Write-Host "Creating application logfiles directory" -ForegroundColor Yellow
	$LogsPath = "C:\inetpub\logs\LogFiles"
	$SiteLogsPath = "$LogsPath" + "\" + "$sitename"
	if (!(Test-Path $SiteLogsPath)) {
	    New-Item -ItemType Directory -Path $SiteLogsPath
	}

	function Select-IPAddress {
		[cmdletbinding()]
		Param(
		    [System.String]$ComputerName='localhost'
		)
		$IPs=Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" | ForEach-Object {
		    $_.IPAddress
		} | Where-Object {
		    $_ -match "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
		}

		if($IPs -is [array]){
		    Write-Host "`nServer $ComputerName uses these IP addresses:"
		    $IPs | ForEach-Object {$Id=0} {Write-Host "${Id}: $_" -ForegroundColor Yellow; $Id++}
		    $IPs[(Read-Choice -Message "`nChoose an IP Address" -Choices (0..($Id-1)) -DefaultChoice 0)]
		}
		else{$IPs}
		}
	$ChosenIP=Select-IPAddress
	Write-Host "`nThe selected IP address is: $ChosenIP`n" -ForegroundColor DarkGreen

	Import-Module "WebAdministration" -ErrorAction Stop
	if ($Pipeline -eq "Integrated") {$PipelineMode="0"} else {$PipelineMode="1"}

	# Creates the ApplicationPool
	Write-Host "Creating website application pool" -ForegroundColor Yellow
	New-WebAppPool -Name $SiteName -Force
	Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name processModel.identityType -Value $Identity
	Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name managedRuntimeVersion -Value $Runtime
	Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name managedPipelineMode -Value $PipelineMode

	# Creates the website
	Write-Host "Creating website" -ForegroundColor Yellow
	New-Website -Name $sitename -Port $port -HostHeader $hostname -IPAddress $ChosenIP -PhysicalPath $directory -ApplicationPool $sitename -Force
	Set-ItemProperty ("IIS:\Sites\" + $sitename) -Name logfile.directory -Value $SiteLogsPath

	Start-WebAppPool -Name $SiteName
	Start-WebSite $SiteName

	Write-Host "Website $SiteName created" -ForegroundColor DarkGreen
	$teste = Read-Host "a"
}

$host.ui.RawUI.WindowTitle = "Edit Bootstrap/start.php"
$conf_bootstrap = "n"
do {
	Clear-Host
	title
	Write-Host "`n*****************************************************************" -Foreground Yellow
	Write-Host "*`tEdit bootstrap/start.php as per documentation`t`t*" -Foreground Yellow
	Write-Host "*`t`t`t`t`t`t`t`t*" -Foreground Yellow
	explorer .\bootstrap
	Write-Host "*`tPlease confirm you have edited bootstrap/start.php`t*" -Foreground Yellow
	Write-Host "*****************************************************************" -Foreground Yellow
	$conf_bootstrap = Read-Host "`nConfirm (y or n)"
}
while ($conf_bootstrap -eq 'n')

Clear-Host
title
$env_choices = [System.Management.Automation.Host.ChoiceDescription[]](
(New-Object System.Management.Automation.Host.ChoiceDescription "&Local","Local"),
(New-Object System.Management.Automation.Host.ChoiceDescription "&Production","Production"),
(New-Object System.Management.Automation.Host.ChoiceDescription "&Staging","Staging"))
$host.ui.RawUI.WindowTitle = "Choose Environment for Snipe-IT"
$Answer = $host.ui.PromptForChoice('Choose your environment for Snipe-IT:',"",$env_choices,(1))

switch ($Answer)
	{
		0 {$env="local"}
		1 {$env="production"}
		2 {$env="staging"}
	}

Rename-Item $directory\app\config\$env\app.example.php app.php
Rename-Item $directory\app\config\$env\database.example.php database.php
Rename-Item $directory\app\config\$env\mail.example.php mail.php

$host.ui.RawUI.WindowTitle = "Edit Config for Environment"
$conf_env = 'n'
do {
	Clear-Host
	title
	Write-Host "`n*********************************************************************************" -Foreground Yellow
	Write-Host "*`tEdit app.php, database.php and mail.php as per documentation`t`t*" -Foreground Yellow
	Write-Host "*`t`t`t`t`t`t`t`t`t`t*" -Foreground Yellow
	explorer $directory\app\config\$env
	Write-Host "*`tPlease confirm you have editted app.php, database.php and mail.php`t*" -Foreground Yellow
	Write-Host "*********************************************************************************" -Foreground Yellow
	$conf_env = Read-Host "`nConfirm (y or n)"
}
while ($conf_env -eq 'n')
Clear-Host
title
$host.ui.RawUI.WindowTitle = "Generating Key"
Write-Host "Generating Key"
php artisan key:generate --env=$env
Clear-Host
title
$host.ui.RawUI.WindowTitle = "Installing Composer"
composer install
Clear-Host
title
$host.ui.RawUI.WindowTitle = "Installing Snipe-IT"
php artisan app:install

#Perms Storage
Write-Host "Allowing IUSR Full Control of app/storage"
cd ./app/storage
$acl = Get-Acl $pwd.Path
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"
$arIUSR = New-Object system.security.AccessControl.FileSystemAccessRule("IUSR", "FullControl", $inherit, $propagation, "Allow")
$acl.SetAccessRule($arIUSR)
Set-Acl $pwd.Path $acl
cd ../..

#Perms Private Uploads
Write-Host "Allowing IUSR Full Control of app/private_uploads"
cd ./app/private_uploads
$acl = Get-Acl $pwd.Path
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"
$arIUSR = New-Object system.security.AccessControl.FileSystemAccessRule("IUSR", "FullControl", $inherit, $propagation, "Allow")
$acl.SetAccessRule($arIUSR)
Set-Acl $pwd.Path $acl
cd ../..

#Perms Public Uploads
Write-Host "Allowing IUSR Full Control of public/uploads"
cd ./public/uploads
$acl = Get-Acl $pwd.Path
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"
$arIUSR = New-Object system.security.AccessControl.FileSystemAccessRule("IUSR", "FullControl", $inherit, $propagation, "Allow")
$acl.SetAccessRule($arIUSR)
Set-Acl $pwd.Path $acl
cd ../..
Set-ConsoleFont