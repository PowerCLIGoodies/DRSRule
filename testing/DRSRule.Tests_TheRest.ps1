<#  .Description
    Pester tests for DRSRule PowerShell module.  Expects that:
    0) DRSRule module is already loaded (but, will try to load it if not)
    1) a connection to at least one vCenter is in place
    2) there are one or more existing connected VMHosts in the specified cluster (on which to make temporary VM objects, and which to use in DRS Rule test, like VMHost rules, groups, etc.)

    .Example
    Invoke-Pester -Script @{Path = '\\some\path\DRSRule\testing\DRSRule.Tests_TheRest.ps1'; Parameters = @{Cluster = "myFavoriteCluster"}}
    Invokes the tests in said Tests script, passing the given Cluster parameter value, to be used for the cluster-specific tests
#>
param (
    ## Name of the vCenter cluster to use in the DRSRule testing
    [parameter(Mandatory=$true)][string]$Cluster
)

## initialize things, preparing for tests
$oClusterToUse = & $PSScriptRoot\DRSRule.TestingInit.ps1 -Cluster $Cluster

Describe -Tags "New" -Name "New DRSRule Items" {
    BeforeAll {
        # BeforeAll block runs _once_ at invocation regardless of number of tests/contexts/describes.
        # Put any setup tasks in here that are required to perform your tests
        Write-Verbose -Verbose "Performing setup tasks for DRSRule tests"

        ## GUID to use as suffix for some temporary vSphere/NSX objects, so as to prevent any naming conflict with existing objects
        $strSuffixGuid = [System.Guid]::NewGuid().Guid.Replace("-","")
        Write-Verbose -Verbose "Using following GUID as suffix on temporary objects' names for ensuring unique object naming: '$strSuffixGuid'"

        ## get some spot in which to create a couple of empty VMs, for use in tests (checking for SecurityTag assignments, for example)
        $script:oVMHostToUse = $oClusterToUse | Get-VMHost -State Connected | Get-Random
        Write-Verbose -Verbose "Using VMHost '$oVMHostToUse' for temporary VM creation"
        ## get the datastore mounted on this VMHost as readWrite (where .ExtensionData.Host.Key is this VMHost's ID, and where .ExtensionData.Host.MountInfo.AccessMode is "readWrite") and with the most FreespaceGB, on which to create some test VMs
        $script:oDStoreToUse = $oVMHostToUse | Get-Datastore | Where-Object {$_.ExtensionData.Host | Where-Object {$_.Key -eq $oVMHostToUse.Id -and ($_.MountInfo.AccessMode -eq "readWrite")}} | Sort-Object -Property FreespaceGB -Descending | Select-Object -First 1
        Write-Verbose -Verbose "Using datastore '$oDStoreToUse' for temporary VM creation"
        ## hashtable of objects that the tests will create; hashtable will then be used as the collection of objects to delete at clean-up time
        $script:hshTemporaryItemsToDelete = @{VM = @(); DrsVMGroup = @(); DrsVMhostGroup = @(); DrsVMtoVMHostRule = @(); DrsVMtoVMRule = @()}

        ## get some items for testing
        Write-Verbose -Verbose "Getting some VMs for testing (making some VMs in the process)"
        $script:hshTemporaryItemsToDelete["VM"] = 0..5 | Foreach-Object {New-VM -Name "pesterTestVM${_}_toDelete-$strSuffixGuid" -Description "test VM for Pester testing" -VMHost $oVMHostToUse -Datastore $oDStoreToUse}
    } ## end BeforeAll


## make tests here!
    # Context -Name "Get-TagAssignment (by SecurityTag)" -Fixture {
    #     It -Name "Gets security tag assignment by security tag" -Test {
    #         $bGetsSecurityTagAssignmentBySecurityTag = $null -ne ($script:SecurityTagWithAssignment | Get-NSXSecurityTagAssignment)
    #         $bGetsSecurityTagAssignmentBySecurityTag | Should Be $true
    #     } ## end it

    #     It -Name "Gets `$null when getting security tag assignment by security tag that has no assignments" -Test {
    #         $bGetsNullForSecurityTagAssignmentBySecurityTagWithNoAssignment = $null -eq ($script:SecurityTagWithoutAssignment | Get-NSXSecurityTagAssignment)
    #         $bGetsNullForSecurityTagAssignmentBySecurityTagWithNoAssignment | Should Be $true
    #     } ## end it
    # } ## end context


    AfterAll {
        # AfterAll block runs _once_ at completion of invocation regardless of number of tests/contexts/describes.
        # Clean up anything you create in here.  Be forceful - you want to leave the test env as you found it as much as is possible.
        ## remove the temporary, test VMs (first make sure that there are some to remove)
        if (($hshTemporaryItemsToDelete["VM"] | Measure-Object).Count -gt 0) {Remove-VM -VM $hshTemporaryItemsToDelete["VM"] -DeletePermanently -Confirm:$false -Verbose}
    } ## end AfterAll
}
