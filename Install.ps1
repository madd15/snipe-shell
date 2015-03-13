Import-Module .\psfont.psm1
Set-ConsoleFont 11
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

####################################################################################################################################################################
Clear-Host
title
Write-Host "`n*************************************************" -Foreground Yellow
Write-Host "*`tWould you like to setup the IIS Site`t*" -Foreground Yellow
Write-Host "*************************************************" -Foreground Yellow
$iis = Read-Host "`nConfirm (y or n)"
if($iis -eq 'y' -Or $iis -eq 'Y')
{
	
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

Rename-Item .\app\config\$env\app.example.php app.php
Rename-Item .\app\config\$env\database.example.php database.php
Rename-Item .\app\config\$env\mail.example.php mail.php

$host.ui.RawUI.WindowTitle = "Edit Config for Environment"
$conf_env = 'n'
do {
	Clear-Host
	title
	Write-Host "`n*********************************************************************************" -Foreground Yellow
	Write-Host "*`tEdit app.php, database.php and mail.php as per documentation`t`t*" -Foreground Yellow
	Write-Host "*`t`t`t`t`t`t`t`t`t`t*" -Foreground Yellow
	explorer .\app\config\$env
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