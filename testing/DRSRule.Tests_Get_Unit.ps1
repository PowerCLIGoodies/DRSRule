<#	.Description
	Pester tests for DRSRule PowerShell module.  Expects that:
	0) DRSRule module is already loaded (but, will try to load it if not)
	1) a connection to at least one vCenter is in place (but, will prompt for XMS to which to connect if not)
#>
param (
	## Name of the vCenter cluster to use in the DRSRule testing
	[parameter(Mandatory=$true)][string]$Cluster
)

## initialize things, preparing for tests
. $PSScriptRoot\DRSRule.TestingInit.ps1 -Cluster $Cluster


## for each of the object types whose typenames match the object name in the cmdlet noun, test getting such an object
$arrObjectTypesToGet = Write-Output VMGroup
$arrObjectTypesToGet | Foreach-Object {
	Describe -Tags "Get" -Name "Get-Drs$_" {
	    It "Gets a DRSRule $_ object" {
	 		$arrReturnTypes = if ($arrTmpObj = Invoke-Command -ScriptBlock {& "Get-Drs$_" | Select-Object -First 2}) {$arrTmpObj | Get-Member -ErrorAction:Stop | Select-Object -Unique -ExpandProperty TypeName} else {$null}
	    	New-Variable -Name "bGetsOnly${_}Type" -Value ($arrReturnTypes -eq "DRSRule.$_")
	    	(Get-Variable -ValueOnly -Name "bGetsOnly${_}Type") | Should Be $true
	    }
	}
}
