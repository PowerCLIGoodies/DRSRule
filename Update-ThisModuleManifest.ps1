<#	.Description
	Some code to help automate the updating of the ModuleManifest file (will create it if it does not yet exist, too)
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
	## Recreate the manifest (overwrite with full, fresh copy instead of update?)
	[Switch]$Recreate
)
begin {
	$strModuleName = "DRSRule"
	$strModuleFolderFilespec = "$PSScriptRoot\$strModuleName"
	$strFilespecForPsd1 = Join-Path $strModuleFolderFilespec "${strModuleName}.psd1"

	## parameters for use by both New-ModuleManifest and Update-ModuleManifest
	$hshManifestParams = @{
		# Confirm = $true
		Path = $strFilespecForPsd1
		ModuleVersion = "2.0.0"
		Author = "Luc Dekens (@LucD22), Matt Boren (@mtboren)"
		CompanyName = 'PowerCLIGoodies'
		Copyright = "MIT License"
		Description = "Module with functions to manage VMware DRS rule items (rules, VM- and VMHost groups, etc)"
		# AliasesToExport = @()
		FileList = Write-Output "${strModuleName}.psd1" "${strModuleName}.psm1" "en-US\about_${strModuleName}.help.txt" "${strModuleName}.format.ps1xml" "${strModuleName}.Help.xml" "${strModuleName}.init.ps1" "${strModuleName}Util.psd1" "${strModuleName}Util.psm1"
		FormatsToProcess = "${strModuleName}.format.ps1xml"
		FunctionsToExport = Write-Output Get-DrsVMGroup Get-DrsVMHostGroup Get-DrsVMToVMHostRule Get-DrsVMToVMRule New-DrsVMGroup New-DrsVMHostGroup New-DrsVMToVMHostRule New-DrsVMToVMRule Remove-DrsVMGroup Remove-DrsVMHostGroup Remove-DrsVMToVMHostRule Remove-DrsVMToVMRule Set-DrsVMGroup Set-DrsVMHostGroup Set-DrsVMToVMHostRule Set-DrsVMToVMRule Import-DrsRule Export-DrsRule
		IconUri = "https://avatars2.githubusercontent.com/u/10615837"
		LicenseUri = "https://github.com/PowerCLIGoodies/DRSRule/blob/master/MITLicense.txt"
		NestedModules = Write-Output "${strModuleName}Util"
		PowerShellVersion = [System.Version]"5.0"
		ProjectUri = "https://github.com/PowerCLIGoodies/DRSRule"
		ReleaseNotes = "See ReadMe and other docs at https://github.com/PowerCLIGoodies/DRSRule, ChangeLog at https://github.com/PowerCLIGoodies/DRSRule/blob/master/changelog.md"
		RequiredModules = "VMware.VimAutomation.Core"
		RootModule = "${strModuleName}.psm1"
		ScriptsToProcess = "${strModuleName}.init.ps1"
		Tags = Write-Output DRS DRSRule VMwareDRS VMGroup VMHostGroup VMToVMRule VMToVMHostRule PowerCLIGoodies
		# Verbose = $true
	} ## end hashtable

	# $hshUpdateManifestParams = @{
	# 	## modules that are external to this module and that this module requires; per help, "Specifies an array of external module dependencies"
	# 	ExternalModuleDependencies = VMware.VimAutomation.Vds
	# }
} ## end begin

process {
	$bManifestFileAlreadyExists = Test-Path $strFilespecForPsd1
	## check that the FileList property holds the names of all of the files in the module directory, relative to the module directory
	## the relative names of the files in the module directory (just filename for those in module directory, "subdir\filename.txt" for a file in a subdir, etc.)
	$arrRelativeNameOfFilesInModuleDirectory = Get-ChildItem $strModuleFolderFilespec -Recurse | Where-Object {-not $_.PSIsContainer} | ForEach-Object {$_.FullName.Replace($strModuleFolderFilespec, "").TrimStart("\")}
	if ($null -eq (Compare-Object -ReferenceObject $hshManifestParams.FileList -DifferenceObject $arrRelativeNameOfFilesInModuleDirectory)) {Write-Verbose -Verbose "Hurray, all of the files in the module directory are named in the FileList property to use for the module manifest"} else {Write-Error "Uh-oh -- FileList property value for making/updating module manifest and actual files present in module directory do not match. Better check that."}
	$strMsgForShouldProcess = "{0} module manifest" -f $(if ((-not $bManifestFileAlreadyExists) -or $Recreate) {"Create"} else {"Update"})
	if ($PsCmdlet.ShouldProcess($strFilespecForPsd1, $strMsgForShouldProcess)) {
		## do the actual module manifest creation/update
		if ((-not $bManifestFileAlreadyExists) -or $Recreate) {Microsoft.PowerShell.Core\New-ModuleManifest @hshManifestParams}
		else {PowerShellGet\Update-ModuleManifest @hshManifestParams}
		## replace the comment in the resulting module manifest that includes "PSGet_" prefixed to the actual module name with a line without "PSGet_" in it
		(Get-Content -Path $strFilespecForPsd1 -Raw).Replace("# Module manifest for module 'PSGet_$strModuleName'", "# Module manifest for module '$strModuleName'") | Set-Content -Path $strFilespecForPsd1
	} ## end if
} ## end process
