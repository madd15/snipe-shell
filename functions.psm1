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
function downloadFile($url, $targetFile) {
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