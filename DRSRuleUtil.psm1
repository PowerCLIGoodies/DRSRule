## functions that are used by the module, but not published for end-user consumption

Function Get-DrsRuleObject
{
  <#  .Description
      Supporting function to get Rule object of given type
  #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Object,
    [String]$Type
  )

  Process
  {
    $Object | where {$_.Type -match $Type}
  }
}

function Get-ClusterObjFromClusterParam
{
	<#	.Description
		Function to get cluster object(s) from given PSObject (expecting string, ClusterImpl object, or $null). If $null, then gets all clusters in connected VIServers
		.Outputs
		ClusterImpl objects
	#>
	param(
		[PSObject[]]$Cluster
	)

  process {
    if($null -eq $Cluster) {Get-Cluster}
    else {
      $Cluster | Foreach-Object {
        if($_ -is [System.String]){
          Get-Cluster -Name $_
        }
        else{$_}
      }
    }
  }
} ## end function

function _Test-TypeOrString
{
  <#  .Description
      Helper function to test if object is either of type String or $Type
      .Outputs
      Boolean -- $true if objects are all either String or the given $Type; $false otherwise
  #>
  param(
    ## Object to test
    [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][PSObject[]]$ObjectToTest,
    ## Type of object for which to check
    [parameter(Mandatory=$true)][Type]$Type
  )

  process {
    ## make sure that all values are either a String or a Cluster obj
    $arrCheckBoolValues = $ObjectToTest | Foreach-Object {($_ -is [System.String]) -or ($_ -is $Type)}
    return (($arrCheckBoolValues -contains $true) -and ($arrCheckBoolValues -notcontains $false))
  }
} ## end function
