<#  .Description
    Pester tests for DRSRule PowerShell module.  Expects that:
    0) DRSRule module is already loaded (but, will try to load it if not)
    1) a connection to at least one vCenter is in place
    2) there are one or more existing connected VMHosts in the specified cluster (on which to make temporary VM objects, and which to use in DRS Rule test, like VMHost rules, groups, etc.)
    3) there are two or more total VMHosts in the specified cluster (which to add to a VMHostGroup)

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

Describe -Name "New-, Set-, Remove- DRSRule Items" {
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
        $arrVMNameIncrementerInts = 0..3
        Write-Verbose -Verbose "Getting some VMs for testing (making '$(($arrVMNameIncrementerInts | Measure-Object).Count)' VMs in the process)"
        $script:hshTemporaryItemsToDelete["VM"] = $arrVMNameIncrementerInts | Foreach-Object {New-VM -Name "pesterTestVM${_}_toDelete-$strSuffixGuid" -Description "test VM for Pester testing" -VMHost $oVMHostToUse -Datastore $oDStoreToUse}
    } ## end BeforeAll


    Context -Name "New DrsVMGroup" -Fixture {
        It -Name "Creates a new DrsVMGroup with some VM members" -Test {
            $script:hshTemporaryItemsToDelete["DrsVMGroup"] = New-DrsVMGroup -Name "pesterTestVMGroup${_}_toDelete-$strSuffixGuid" -Cluster $oClusterToUse -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 2)
            $bCreatesNewVMGroup = $null -eq (($script:hshTemporaryItemsToDelete["DrsVMGroup"] | Should HaveCount 1), ($script:hshTemporaryItemsToDelete["DrsVMGroup"] | Should BeOfType DRSRule_VMGroup) | Select-Object -Unique)
            $bCreatesNewVMGroup | Should Be $true
        } ## end it
    } ## end context

    Context -Name "New DrsVMHostGroup" -Fixture {
        It -Name "Creates a new DrsVMHostGroup with a VMHost member" -Test {
            $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] = New-DrsVMHostGroup -Name "pesterTestVMHostGroup${_}_toDelete-$strSuffixGuid" -Cluster $oClusterToUse -VMHost ($oClusterToUse | Get-VMHost | Select-Object -First 1)
            $bCreatesNewVMHostGroup = $null -eq (($script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Should HaveCount 1), ($script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Should BeOfType DRSRule_VMHostGroup) | Select-Object -Unique)
            $bCreatesNewVMHostGroup | Should Be $true
        } ## end it
    } ## end context

    Context -Name "New DrsVMtoVMHostRule" -Fixture {
        It -Name "Creates a new DrsVMtoVMHostRule" -Test {
            $bCreatesNewVMtoVMHostRule = $false
            $bCreatesNewVMtoVMHostRule | Should Be $true
        } ## end it
    } ## end context

    Context -Name "New DrsVMtoVMRule" -Fixture {
        It -Name "Creates a new DrsVMtoVMRule" -Test {
            $bCreatesNewVMtoVMRule = $false
            $bCreatesNewVMtoVMRule | Should Be $true
        } ## end it
    } ## end context


    Context -Name "Set DrsVMGroup" -Fixture {
        It -Name "Sets a DrsVMGroup VM members (adds a VM via -AddVM parameter, and with a VM object)" -Test {
            $intNumGroupMemberBeforeAdd = $($oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1; (Get-DrsVMGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster).VM.Count)
            $oTmpGroup_afterAdd = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1 | Set-DrsVMGroup -AddVM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1 -Skip 2)
            $intNumGroupMemberAfterAdd = $oTmpGroup_afterAdd.VM.Count
            $bAddsVMGroupMember = ($intNumGroupMemberAfterAdd - $intNumGroupMemberBeforeAdd) -eq 1
            $bAddsVMGroupMember | Should Be $true
        } ## end it

        It -Name "Sets a DrsVMGroup VM members (adds a VM via -Append and -VM parameters, and with a VM object)" -Test {
            $intNumGroupMemberBeforeAdd = $($oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1; (Get-DrsVMGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster).VM.Count)
            $oTmpGroup_afterAdd = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1 | Set-DrsVMGroup -Append -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1 -Skip 3)
            $intNumGroupMemberAfterAdd = $oTmpGroup_afterAdd.VM.Count
            $bAddsVMGroupMember = ($intNumGroupMemberAfterAdd - $intNumGroupMemberBeforeAdd) -eq 1
            $bAddsVMGroupMember | Should Be $true
        } ## end it

        It -Name "Sets a DrsVMGroup VM members (removes a VM via -RemoveVM parameter, and with a VM by name)" -Test {
            $intNumGroupMemberBeforeRemove = $($oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1; (Get-DrsVMGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster).VM.Count)
            $oTmpGroup_afterRemove = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1 | Set-DrsVMGroup -RemoveVM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1).Name
            $intNumGroupMemberAfterRemove = $oTmpGroup_afterRemove.VM.Count
            $bAddsVMGroupMember = ($intNumGroupMemberBeforeRemove - $intNumGroupMemberAfterRemove) -eq 1
            $bAddsVMGroupMember | Should Be $true
        } ## end it

        It -Name "Sets a DrsVMGroup VM members (Sets explicit member list via just -VM parameter, and with a VM by name)" -Test {
            $oTmpGroup_afterSet = $script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1 | Set-DrsVMGroup -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1).Name
            $bSetsExplicitVMGroupMember = ($oTmpGroup_afterSet.VM.Count -eq 1) -and ($oTmpGroup_afterSet.VM -eq ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1).Name)
            $bSetsExplicitVMGroupMember | Should Be $true
        } ## end it
    } ## end context


    Context -Name "Set DrsVMHostGroup" -Fixture {
        It -Name "Sets a DrsVMHostGroup VMHost members (adds a VMHost via -AddVMHost parameter, and with a VMHost object)" -Test {
            $intNumGroupMemberBeforeAdd = $($oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1; (Get-DrsVMHostGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster).VMHost.Count)
            $oVMHostToAdd = $oClusterToUse | Get-VMHost | Where-Object {$_.Name -notin $oTmpGroup.VMHost} | Get-Random
            $oTmpGroup_afterAdd = $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1 | Set-DrsVMHostGroup -AddVMHost $oVMHostToAdd
            $intNumGroupMemberAfterAdd = $oTmpGroup_afterAdd.VMHost.Count
            $bAddsVMHostGroupMember = (($intNumGroupMemberAfterAdd - $intNumGroupMemberBeforeAdd) -eq 1) -and ($oTmpGroup_afterAdd.VMHost -contains $oVMHostToAdd.Name)
            $bAddsVMHostGroupMember | Should Be $true
        } ## end it

        It -Name "Sets a DrsVMHostGroup VMHost members (removes a VMHost via -RemoveVMHost parameter, and with a VMHost by name)" -Test {
            $intNumGroupMemberBeforeRemove = $($oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1; ($oTmpGroup = Get-DrsVMHostGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster).VMHost.Count)
            $strVMHostNameToRemove = $oTmpGroup.VMHost | Get-Random
            $oTmpGroup_afterRemove = $oTmpGroup | Set-DrsVMHostGroup -RemoveVMHost $strVMHostNameToRemove
            $intNumGroupMemberAfterRemove = $oTmpGroup_afterRemove.VMHost.Count
            ## is the count less by 1, and is the name of the supposedly removed group member no long in the updated group?
            $bAddsVMHostGroupMember = (($intNumGroupMemberBeforeRemove - $intNumGroupMemberAfterRemove) -eq 1) -and ($strVMHostNameToRemove -notin $oTmpGroup_afterRemove.VMHost)
            $bAddsVMHostGroupMember | Should Be $true
        } ## end it

        It -Name "Sets a DrsVMHostGroup VMHost members (adds a VMHost via -Append and -VMHost parameters, and with a VMHost object)" -Test {
            $intNumGroupMemberBeforeAdd = $($oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1; ($oTmpGroup = Get-DrsVMHostGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster).VMHost.Count)
            $oVMHostToAdd = $oClusterToUse | Get-VMHost | Where-Object {$_.Name -notin $oTmpGroup.VMHost} | Get-Random
            $oTmpGroup_afterAdd = $oTmpGroup | Set-DrsVMHostGroup -VMHost $oVMHostToAdd -Append
            $intNumGroupMemberAfterAdd = $oTmpGroup_afterAdd.VMHost.Count
            $bAddsVMHostGroupMember = (($intNumGroupMemberAfterAdd - $intNumGroupMemberBeforeAdd) -eq 1) -and ($oTmpGroup_afterAdd.VMHost -contains $oVMHostToAdd.Name)
            $bAddsVMHostGroupMember | Should Be $true
        } ## end it

        It -Name "Sets a DrsVMHostGroup VMHost members (Sets explicit member list via just -VMHost parameter, and with a VMHost by name)" -Test {
            $oTmpGroup = $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1; $oTmpGroup = Get-DrsVMHostGroup -Name $oTmpGroup.Name -Cluster $oTmpGroup.Cluster
            $oVMHostForSet = $oClusterToUse | Get-VMHost | Get-Random
            $oTmpGroup_afterSet = $oTmpGroup | Set-DrsVMHostGroup -VMHost $oVMHostForSet.Name
            $bSetsExplicitVMHostGroupMember = ($oTmpGroup_afterSet.VMHost.Count -eq 1) -and ($oTmpGroup_afterSet.VMHost -eq $oVMHostForSet.Name)
            $bSetsExplicitVMHostGroupMember | Should Be $true
        } ## end it
    } ## end context


    Context -Name "Remove DrsVMGroup" -Fixture {
        It -Name "Removes DrsVMGroup (which was created for this testing)" -Test {
            $arrTemporaryDrsGroupNames = $script:hshTemporaryItemsToDelete["DrsVMGroup"].Name
            ## should remove group successfully, and subsequent Get- of group should return zero objects
            $bRemovesDrsVMGroup = $null -eq (({$script:hshTemporaryItemsToDelete["DrsVMGroup"] | Remove-DrsVMGroup -Verbose -Confirm:$false} | Should Not Throw), ($arrTemporaryDrsGroupNames | Foreach-Object {Get-DrsVMGroup -Name $_ -Cluster $oClusterToUse} | Should Be $null) | Select-Object -Unique)
            $bRemovesDrsVMGroup | Should Be $true
        } ## end it
    } ## end context

    Context -Name "Remove DrsVMHostGroup" -Fixture {
        It -Name "Removes DrsVMHostGroup (which was created for this testing)" -Test {
            $arrTemporaryDrsGroupNames = $script:hshTemporaryItemsToDelete["DrsVMHostGroup"].Name
            ## should remove group successfully, and subsequent Get- of group should return zero objects
            $bRemovesDrsVMHostGroup = $null -eq (({$script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Remove-DrsVMHostGroup -Verbose -Confirm:$false} | Should Not Throw), ($arrTemporaryDrsGroupNames | Foreach-Object {Get-DrsVMGroup -Name $_ -Cluster $oClusterToUse} | Should Be $null) | Select-Object -Unique)
            $bRemovesDrsVMHostGroup | Should Be $true
        } ## end it
    } ## end context

    AfterAll {
        # AfterAll block runs _once_ at completion of invocation regardless of number of tests/contexts/describes.
        # Clean up anything you create in here.  Be forceful - you want to leave the test env as you found it as much as is possible.
        ## remove the temporary, test VMs (first make sure that there are some to remove)
        if (($hshTemporaryItemsToDelete["VM"] | Measure-Object).Count -gt 0) {Remove-VM -VM $hshTemporaryItemsToDelete["VM"] -DeletePermanently -Confirm:$false -Verbose}
        Context -Name "Make sure all are gone" -Fixture {
            It -Name "Ensures that all temporary DRSRule- and VM objects which created for this testing were actually removed" -Test {
                $arrRemainingTestDrsRuleObjects = Write-Output DrsVMGroup, DrsVMHostGroup | Foreach-Object {
                    $strThisDrsItemName = $_
                    $script:hshTemporaryItemsToDelete[$strThisDrsItemName].Name | Foreach-Object {& "Get-$strThisDrsItemName" -Name $_ -Cluster $oClusterToUse}
                } ## end foreach-object
                $arrRemainingTestVMs = Get-VM -Id $script:hshTemporaryItemsToDelete["VM"].Id -ErrorAction:SilentlyContinue
                $bNoRemainingTestDrsRuleObjects = ($arrRemainingTestDrsRuleObjects.Count -eq 0) -and ($arrRemainingTestVMs.Count -eq 0)
                $bNoRemainingTestDrsRuleObjects | Should Be $true
            } ## end it
        } ## end context
    } ## end AfterAll
} ## end describe
