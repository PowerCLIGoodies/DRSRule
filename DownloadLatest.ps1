$moduleName = 'DRSRule'

$url = "http://github.com/PowerCLIGoodies/$($moduleName)/archive/Latest.zip"
$fileName = "$(Get-Location)\Latest.zip"
 
# Download the DRSRule ZIP file
Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $fileName
 
# Create the DRSRule folder in the user's Modules folder
$destination = "$($env:PSModulePath.Split(';') | where {$_ -match "Users"})\DRSRule"

if(Test-Path -Path $destination){
    Remove-Item -Path $destination -Recurse
}
 
New-Item -Path $destination -ItemType directory | Out-Null
 
# Extract the DRSRule module files
$from = "$($fileName)\DRSRule-Latest"
$shell = New-Object -ComObject Shell.Application
$shell.NameSpace($destination).Copyhere(($shell.NameSpace($from)).Items())
 
# Clean up
Remove-Item -Path $fileName -Force
