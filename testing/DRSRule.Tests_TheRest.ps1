<#  .Description
    Pester tests for DRSRule PowerShell module.  Expects that:
    0) DRSRule module is already loaded (but, will try to load it if not)
    1) a connection to at least one vCenter is in place
    2) there are one or more existing connected VMHosts in the specified cluster (on which to make temporary VM objects, and which to use in DRS Rule test, like VMHost rules, groups, etc.)
    3) there are two or more total VMHosts in the specified cluster (which to add to a VMHostGroup)

    .Notes
    No tests in place for Export-DrsRule, Import-DrsRule, yet

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
## check that environmental requirements are met by the target cluster
$arrVMHostInClusterToUse = $oClusterToUse | Get-VMHost
## are there enough VMHosts in Connected state in given cluster?
$bSufficientConnectedVMHostCount = ($arrVMHostInClusterToUse | Where-Object {$_.ConnectionState -eq "Connected"} | Measure-Object).Count -gt 0
## are there enough total VMHosts in given cluster? (need more than one for the VMHostRule tests)
$bSufficientTotalVMHostCount = ($arrVMHostInClusterToUse | Measure-Object).Count -gt 1
if ($bSufficientConnectedVMHostCount -and $bSufficientTotalVMHostCount) {
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


        Describe -Name "New DRSRule Items" {
            Context -Name "New-DrsVMGroup" -Fixture {
                It -Name "Creates a new DrsVMGroup with some VM members" -Test {
                    $script:hshTemporaryItemsToDelete["DrsVMGroup"] = New-DrsVMGroup -Name "pesterTestVMGroup${_}_toDelete-$strSuffixGuid" -Cluster $oClusterToUse -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 2)
                    ## new object should have correct properties and be of given type -- all of the Pester statements should return $null if correct
                    $bCreatesNewVMGroup = $null -eq (($script:hshTemporaryItemsToDelete["DrsVMGroup"] | Should HaveCount 1), ($script:hshTemporaryItemsToDelete["DrsVMGroup"] | Should BeOfType DRSRule_VMGroup) | Select-Object -Unique)
                    $bCreatesNewVMGroup | Should Be $true
                } ## end it
            } ## end context

            Context -Name "New-DrsVMHostGroup" -Fixture {
                It -Name "Creates a new DrsVMHostGroup with a VMHost member" -Test {
                    $script:hshTemporaryItemsToDelete["DrsVMHostGroup"] = New-DrsVMHostGroup -Name "pesterTestVMHostGroup${_}_toDelete-$strSuffixGuid" -Cluster $oClusterToUse -VMHost ($oClusterToUse | Get-VMHost | Select-Object -First 1)
                    ## new object should have correct properties and be of given type -- all of the Pester statements should return $null if correct
                    $bCreatesNewVMHostGroup = $null -eq (($script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Should HaveCount 1), ($script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Should BeOfType DRSRule_VMHostGroup) | Select-Object -Unique)
                    $bCreatesNewVMHostGroup | Should Be $true
                } ## end it
            } ## end context

            Context -Name "New-DrsVMtoVMHostRule" -Fixture {
                It -Name "Creates a new DrsVMtoVMHostRule" -Test {
                    $script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"] = New-DrsVMtoVMHostRule -Name "pesterTestVMtoVMHostRule${_}_toDelete-$strSuffixGuid" -Cluster $oClusterToUse -Enabled:$false -Mandatory:$true -VMGroupName ($script:hshTemporaryItemsToDelete["DrsVMGroup"] | Select-Object -First 1).Name -AffineHostGroupName ($script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1).Name
                    ## new object should have correct properties and be of given type -- all of the Pester statements should return $null if correct
                    $bCreatesNewVMtoVMHostRule = $null -eq (
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"] | Should HaveCount 1),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"] | Should BeOfType DRSRule_VMToVMHostRule),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"].Enabled | Should Be $false),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"].Mandatory | Should Be $true),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"].AffineHostGroupName | Should Be ($script:hshTemporaryItemsToDelete["DrsVMHostGroup"] | Select-Object -First 1).Name) `
                            | Select-Object -Unique
                    )
                    $bCreatesNewVMtoVMHostRule | Should Be $true
                } ## end it
            } ## end context

            Context -Name "New-DrsVMtoVMRule" -Fixture {
                It -Name "Creates a new DrsVMtoVMRule" -Test {
                    $script:hshTemporaryItemsToDelete["DrsVMtoVMRule"] = New-DrsVMtoVMRule -Name "pesterTestVMtoVMRule${_}_toDelete-$strSuffixGuid" -Cluster $oClusterToUse -Enabled:$false -Mandatory -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 2)
                    ## new object should have correct properties and be of given type -- all of the Pester statements should return $null if correct
                    $bCreatesNewVMtoVMRule = $null -eq (
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMRule"] | Should HaveCount 1),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMRule"] | Should BeOfType DRSRule_VMToVMRule),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMRule"].Enabled | Should Be $false),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMRule"].Mandatory | Should Be $true),
                        ($script:hshTemporaryItemsToDelete["DrsVMtoVMRule"].VM | Should Be ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 2).Name) `
                            | Select-Object -Unique
                    )
                    $bCreatesNewVMtoVMRule | Should Be $true
                } ## end it
            } ## end context
        } ## end Describe


        Describe -Name "Set DRSRule Items" {
            Context -Name "Set-DrsVMGroup" -Fixture {
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

                It -Name "Throws when trying to Set-DrsVMGroup on a non-existent Group name" -Test {
                    $bThrowsWithInvalidDRSItemName = $null -eq ({Set-DrsVMGroup -Name ("fakeName-{0}" -f [System.Guid]::NewGuid().Guid) -Cluster $oClusterToUse -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1)} | Should Throw)
                    $bThrowsWithInvalidDRSItemName | Should Be $true
                } ## end it
            } ## end context


            Context -Name "Set-DrsVMHostGroup" -Fixture {
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

                It -Name "Throws when trying to Set-DrsVMHostGroup on a non-existent Group name" -Test {
                    $bThrowsWithInvalidDRSItemName = $null -eq ({Set-DrsVMHostGroup -Name ("fakeName-{0}" -f [System.Guid]::NewGuid().Guid) -Cluster $oClusterToUse -VMHost ($oClusterToUse | Get-VMHost | Get-Random)} | Should Throw)
                    $bThrowsWithInvalidDRSItemName | Should Be $true
                } ## end it
            } ## end context


            Context -Name "Set-DrsVMtoVMHostRule" -Fixture {
                It -Name "Sets a DrsVMtoVMHostRule to be an antiaffinity rule, and makes it 'should run on' instead of 'must run on'" -Test {
                    $oTmpRule = $script:hshTemporaryItemsToDelete["DrsVMtoVMHostRule"] | Select-Object -First 1 | Foreach-Object {Get-DrsVMtoVMHostRule -Name $_.Name -Cluster $_.Cluster}
                    $oTmpRule_afterSet = $oTmpRule | Set-DrsVMtoVMHostRule -Mandatory:$false -KeepTogether:$false
                    ## resulting object should have correct properties -- all of the Pester statements should return $null if correct
                    $bSetsVMtoVMHostRule = $null -eq (
                        ($oTmpRule_afterSet.Mandatory | Should Be $false),
                        ($oTmpRule_afterSet.AntiAffineHostGroupName | Should Be $oTmpRule.AffineHostGroupName) `
                            | Select-Object -Unique
                    )
                    $bSetsVMtoVMHostRule | Should Be $true
                } ## end it

                It -Name "Throws when trying to Set-DrsVMtoVMHostRule on a non-existent Rule name" -Test {
                    $bThrowsWithInvalidDRSItemName = $null -eq ({Set-DrsVMtoVMHostRule -Name ("fakeName-{0}" -f [System.Guid]::NewGuid().Guid) -Cluster $oClusterToUse -Enabled:$false -KeepTogether} | Should Throw)
                    $bThrowsWithInvalidDRSItemName | Should Be $true
                } ## end it
            } ## end context


            Context -Name "Set-DrsVMtoVMRule" -Fixture {
                It -Name "Sets a DrsVMtoVMRule to be an affinity rule (KeepTogether), and makes it 'should' instead of 'must'" -Test {
                    $oTmpRule = $script:hshTemporaryItemsToDelete["DrsVMtoVMRule"] | Select-Object -First 1 | Foreach-Object {Get-DrsVMtoVMRule -Name $_.Name -Cluster $_.Cluster}
                    $oTmpRule_afterSet = $oTmpRule | Set-DrsVMtoVMRule -KeepTogether -Mandatory:$false
                    ## resulting object should have correct properties -- all of the Pester statements should return $null if correct
                    $bSetsVMtoVMRule = $null -eq (
                        ($oTmpRule_afterSet.Mandatory | Should Be $false),
                        ($oTmpRule_afterSet.KeepTogether | Should Be $true) `
                            | Select-Object -Unique
                    )
                    $bSetsVMtoVMRule | Should Be $true
                } ## end it

                It -Name "Sets a DrsVMtoVMRule, adding another VM to the rule" -Test {
                    $oTmpRule = $script:hshTemporaryItemsToDelete["DrsVMtoVMRule"] | Select-Object -First 1 | Foreach-Object {Get-DrsVMtoVMRule -Name $_.Name -Cluster $_.Cluster}
                    $oTmpRule_afterSet = $oTmpRule | Set-DrsVMtoVMRule -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 1 -Skip 2) -Append
                    ## resulting object should have correct properties -- all of the Pester statements should return $null if correct
                    $bSetsVMtoVMRule = $null -eq ($oTmpRule_afterSet.VM | Should Be ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 3).Name)
                    $bSetsVMtoVMRule | Should Be $true
                } ## end it

                It -Name "Sets a DrsVMtoVMRule to be for two other VMs (instead of the original two), and make antiaffinity again" -Test {
                    $oTmpRule = $script:hshTemporaryItemsToDelete["DrsVMtoVMRule"] | Select-Object -First 1 | Foreach-Object {Get-DrsVMtoVMRule -Name $_.Name -Cluster $_.Cluster}
                    $oTmpRule_afterSet = $oTmpRule | Set-DrsVMtoVMRule -VM ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 2 -Skip 2) -KeepTogether:$false
                    ## resulting object should have correct properties -- all of the Pester statements should return $null if correct
                    $bSetsVMtoVMRule = $null -eq (
                        ($oTmpRule_afterSet.VM | Should Be ($script:hshTemporaryItemsToDelete["VM"] | Select-Object -First 2 -Skip 2).Name),
                        ($oTmpRule_afterSet.KeepTogether | Should Be $false) `
                            | Select-Object -Unique
                    )
                    $bSetsVMtoVMRule | Should Be $true
                } ## end it

                It -Name "Throws when trying to Set-DrsVMtoVMRule on a non-existent Rule name" -Test {
                    $bThrowsWithInvalidDRSItemName = $null -eq ({Set-DrsVMtoVMRule -Name ("fakeName-{0}" -f [System.Guid]::NewGuid().Guid) -Cluster $oClusterToUse -KeepTogether} | Should Throw)
                    $bThrowsWithInvalidDRSItemName | Should Be $true
                } ## end it
            } ## end context
        } ## end Describe


        Describe -Name "Remove DRSRule Items" {
            ## make Remove contexts/tests for each of the Cmdlet/Object types
            Write-Output "DrsVMGroup", "DrsVMHostGroup", "DrsVMtoVMHostRule", "DrsVMtoVMRule" | Foreach-Object {
                $strDrsItemOfInterest = $_
                Context -Name "Remove-$strDrsItemOfInterest" -Fixture {
                    It -Name "Removes $strDrsItemOfInterest (which was created for this testing)" -Test {
                        $arrTemporaryDrsRuleItemNames = $script:hshTemporaryItemsToDelete[$strDrsItemOfInterest].Name
                        ## should remove given DRSRule item successfully, and subsequent Get- of given DRSRule item should return zero objects
                        $bRemovesDrsRuleItem = $null -eq (({$script:hshTemporaryItemsToDelete[$strDrsItemOfInterest] | & "Remove-$strDrsItemOfInterest" -Verbose -Confirm:$false} | Should Not Throw), ($arrTemporaryDrsRuleItemNames | Foreach-Object {& "Get-$strDrsItemOfInterest" -Name $_ -Cluster $oClusterToUse} | Should Be $null) | Select-Object -Unique)
                        $bRemovesDrsRuleItem | Should Be $true
                    } ## end it
                } ## end context
            } ## end Foreach-Object
        } ## end Describe

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
} ## end if
else {Write-Warning ("Target cluster '{0}' does not have sufficient VMHosts for running the tests. See the requirements for the test, adjust VMHost situation, and then test." -f $oClusterToUse.Name)}
