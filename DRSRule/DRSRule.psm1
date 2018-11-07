<#  .Description
    Retrieves the DRS VM groups. It returns DRS VM groups that correspond to the filter criteria provided by the cmdlet parameters.

    The default return type holds more information than the "raw" DRS object that vSphere uses.  There is also a switch to allow for just returning said raw DRS object, quite useful for consumption by other cmdlets in this module.

    .Synopsis
    This cmdlet retrieves the DRS VM groups

    .Example
    Get-DrsVMGroup -Name '*VM Group 1*'
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    VM Group 1         Cluster1        True               {VM1,VM2}
    VM Group 12        Cluster1        True               {VM3}
    New VM Group 100   Cluster2        True               {VM4,VM5,VM6}

    Returns all DRS VM groups with name like '*VM Group 1*'

    .Example
    Get-DrsVMGroup -Cluster Cluster1 -Name 'VM Group 1'
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    VM Group 1         Cluster1        True               {VM1,VM2}

    The DRS VM group with the exact name 'VM Group 1' from Cluster1 will be returned

    .Example
    Get-Cluster Cluster2 | Get-DrsVMGroup
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    VM Group 5         Cluster2        True               {VM101,VM102}
    testVMGroup        Cluster2        True               {VM0,VM1001,VM1002}

    Returns all DRS VM groups in cluster "Cluster2"

    .Example
    Get-VM DrsRuleTest1 | Get-DrsVMGroup
    Name             Cluster   UserCreated   VM
    ----             -------   -----------   --
    TestVMGroup1     myClus0   True          {DrsRuleTest1, DrsRuleTest0}

    Gets a DRS VMGroup by the related VM object. Returns the VMGroup(s) of which a VM is a part, if any

    .Outputs
    If corrsponding DRS VMGroup(s) found, either DRSRule_VMGroup in "normal" mode, or VMware.Vim.ClusterVmGroup in "-ReturnRaw" mode. Else, $null

    .Link
    https://github.com/PowerCLIGoodies/DRSRule
    New-DrsVMGroup
    Remove-DrsVMGroup
    Set-DrsVMGroup
#>
function Get-DrsVMGroup {
  [CmdletBinding(DefaultParameterSetName = "ByName")]
  [OutputType([DRSRule_VMGroup],[VMware.Vim.ClusterVmGroup])]
  param(
    ## Name of DRS VM Group to get (or, all if no name specified)
    [Parameter(Position = 0, ParameterSetName="ByName")]
    [string]${Name} = '*',

    ## Cluster from which to get DRS VM group (or, all clusters if no name specified)
    [Parameter(Position = 1, ParameterSetName="ByName", ValueFromPipeline=$True)]
    [PSObject[]]${Cluster},

    ## Virtual Machine for which to get the corresponding DRS VMGroup(s), if any
    [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByRelatedObject")]
    [VMware.VimAutomation.Types.VirtualMachine]$VM,

    ## Switch:  return "raw" VMware.Vim.ClusterVmGroup object (contains less info, but useful to other functions that can consume this raw object)
    [switch]$ReturnRawGroup
  )

  Process {
    ## is this invocation getting item by related object?
    $bByRelatedObject = $PSCmdlet.ParameterSetName -eq "ByRelatedObject"
    ## get cluster object(s) from the Cluster param (if no value was specified -- gets all clusters)
    $arrClustersToCheck = if ($bByRelatedObject) {$VM.VMHost.Parent} else {Get-ClusterObjFromClusterParam -Cluster $Cluster}
    ## for the cluster(s) to check, try to get the pertinent VMGroups
    $arrClustersToCheck | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach ClusterVmGroup item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Group |
      Where-Object -FilterScript {
        ## where it's the given type, and, if ByRelatedObject, it contains the MoRef of this realted object -- else, if the name is like the specified name
        ($_ -is [VMware.Vim.ClusterVmGroup]) -and $(if ($bByRelatedObject) {$_.VM -contains $VM.Id} else {$_.Name -like ${Name}})
      } |
      ForEach-Object -Process {
        if ($true -eq $ReturnRawGroup) {return $_}
        else {
          New-Object -TypeName DRSRule_VMGroup -Property @{
            Name        = $_.Name
            ## updated to use $oThisCluster, instead of $Cluster, which would get all cluster names if more than one cluster
            Cluster     = $oThisCluster.Name
            VM          = $(
                            if($_.Vm) {Get-View $_.Vm -Property Name | Select-Object -ExpandProperty Name}
                            else {$null}
                          )
            VMId        = $_.Vm
            UserCreated = [Boolean]$_.UserCreated
            Type        = $_.GetType().Name
          }
        }
      }
    }
  }
}


<#  .Description
    This cmdlet retrieves the DRS VM groups.
    It returns DRS VM groups that correspond to the filter criteria provided by the cmdlet parameters.

    The default return type holds more information than the "raw" DRS object that vSphere uses.  There is also a switch to allow for just returning said raw DRS object, quite useful for consumption by other cmdlets in this module.

    .Synopsis
    Retrieves the DRS VMHost groups

    .Example
    Get-DRSVMHostGroup -Name '*VMHost Group 1*'
    Name               Cluster         UserCreated        VMHost
    ----               -------         -----------        ------
    VMHost Group 1     Cluster1        True               {esx1,esx2}
    VMHost Group 12    Cluster1        True               {esx3}
    New VMHost Group 1 Cluster2        True               {esx4,esx5,esx6}

    Returns all DRS VMHost groups with name like '*VMHost Group 1*'

    .Example
    Get-DRSVMHostGroup -Cluster Cluster1 -Name 'VMHost Group 1'
    Name               Cluster         UserCreated        VMHost
    ----               -------         -----------        ------
    VMHost Group 1     Cluster1        True               {esx1,esx2}

    The DRS VMHost group with the exact name 'VMHost Group 1' from Cluster1 will be returned

    .Example
    Get-Cluster Cluster2 | Get-DrsVMHostGroup
    Name               Cluster         UserCreated        VMHost
    ----               -------         -----------        ------
    oldVMHostGroup     Cluster2        True               {esx11,esx12}
    VMHost Group DR    Cluster2        True               {esx13}
    New VMHost Grp 3   Cluster2        True               {esx14,esx15,esx16}

    Returns all DRS VMHost groups in cluster "Cluster2"

    .Example
    Get-VMHost esx11 | Get-DrsVMHostGroup
    Name             Cluster   UserCreated   VMHost
    ----             -------   -----------   ------
    oldVMHostGroup   Cluster2  True          {esx11,esx12}

    Gets a DRS VMHostGroup by the related VMHost object. Returns the VMHostGroup(s) of which a VMHost is a part, if any

    .Outputs
    If corrsponding DRS VMHostGroup(s) found, either DRSRule_VMHostGroup in "normal" mode, or VMware.Vim.ClusterHostGroup in "-ReturnRaw" mode. Else, $null

    .Link
    https://github.com/PowerCLIGoodies/DRSRule
    New-DrsVMHostGroup
    Remove-DrsVMHostGroup
    Set-DrsVMHostGroup
#>
function Get-DrsVMHostGroup {
  [CmdletBinding(DefaultParameterSetName = "ByName")]
  [OutputType([DRSRule_VMHostGroup],[VMware.Vim.ClusterHostGroup])]
  param(
    ## Name of DRS VMHost Group to get (or, all if no name specified)
    [Parameter(Position = 0, ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [string]${Name} = '*',

    ## Cluster from which to get DRS VMHost group (or, all clusters if no name specified)
    [Parameter(Position = 1, ParameterSetName="ByName", ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]${Cluster},

    ## VMHost for which to get the corresponding DRS VMHostGroup(s), if any
    [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByRelatedObject")]
    [VMware.VimAutomation.Types.VMHost]$VMHost,

    ## Switch:  return "raw" VMware.Vim.ClusterHostGroup object (contains less info, but useful to other functions that can consume this raw object)
    [switch]$ReturnRawGroup
  )

  Process{
    ## is this invocation getting item by related object?
    $bByRelatedObject = $PSCmdlet.ParameterSetName -eq "ByRelatedObject"
    ## get cluster object(s) from the Cluster param (if no value was specified -- gets all clusters)
    $arrClustersToCheck = if ($bByRelatedObject) {$VMHost.Parent} else {Get-ClusterObjFromClusterParam -Cluster $Cluster}
    ## for the cluster(s) to check, try to get the pertinent VMHostGroups
    $arrClustersToCheck | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach ClusterVmGroup item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Group |
      Where-Object -FilterScript {
        ($_ -is [VMware.Vim.ClusterHostGroup]) -and $(if ($bByRelatedObject) {$_.Host -contains $VMHost.Id} else {$_.Name -like ${Name}})
      } |
      ForEach-Object -Process {
        if ($true -eq $ReturnRawGroup) {return $_}
        else {
          New-Object DRSRule_VMHostGroup -Property @{
            Name        = $_.Name
            Cluster     = $oThisCluster.Name
            VMHost      = $(
                            if($_.Host) {Get-View $_.Host -Property Name | Select-Object -ExpandProperty Name}
                            else {$null}
                          )
            VMHostId    = $_.Host
            UserCreated = [Boolean]$_.UserCreated
            Type        = $_.GetType().Name
          }
        }
      }
    }
  }
}


<#  .Description
    This cmdlet retrieves the DRS VM to VM rules.
    It returns DRS VM to VM rules that correspond to the filter criteria provided by the cmdlet parameters.
    The VM to VM rules can be either affinity- or anti-affinity rules.

    The default return type holds more information than the "raw" DRS object that vSphere uses.  There is also a switch to allow for just returning said raw DRS object, quite useful for consumption by other cmdlets in this module.

    .Synopsis
    Retrieves the DRS VM to VM rules

    .Example
    Get-DrsVMToVMRule -Name 'Rule 1*'
    Name         Cluster         Enabled     KeepTogether  Mandatory   VM
    ----         -------         -------     ------------  ---------   --
    Rule 1       Cluster1        False       False         False       {VM1, VM2}
    Rule 12      Cluster2        True        True          True        {VM3, VM4}

    Returns all DRS VM to VM rules with name like 'Rule 1*'

    .Example
    Get-Cluster Cluster2 | Get-DrsVMtoVMRule
    Name         Cluster         Enabled     KeepTogether  Mandatory   VM
    ----         -------         -------     ------------  ---------   --
    Rule 0       Cluster2        False       False         False       {VM101, VM102}
    Rule 11      Cluster2        True        True          True        {VM103, VM014}
    Rule_old     Cluster2        False       True          True        {VM110, VM111}

    Returns all DRS VM to VM rules in Cluster2

    .Example
    Get-VM VM3 | Get-DrsVMToVMRule
    Name         Cluster         Enabled     KeepTogether  Mandatory   VM
    ----         -------         -------     ------------  ---------   --
    Rule 12      Cluster2        True        True          True        {VM3, VM4}

    Returns all DRS VM to VM rules involving the specified VM, "VM3"

    .Outputs
    DRSRule_VMToVMRule object with information about the given DRS VM to VM rule, or a raw vSphere object of on of the types VMware.Vim.ClusterAffinityRuleSpec or VMware.Vim.ClusterAntiAffinityRuleSpec, depending on if the rule is affinity or anti-affinity

    .Link
    https://github.com/PowerCLIGoodies/DRSRule
    New-DrsVMToVMRule
    Remove-DrsVMToVMRule
    Set-DrsVMToVMRule
#>
function Get-DrsVMToVMRule {
  [CmdletBinding(DefaultParameterSetName = "ByName")]
  [OutputType([DRSRule_VMToVMRule],[VMware.Vim.ClusterAffinityRuleSpec],[VMware.Vim.ClusterAntiAffinityRuleSpec])]
  param(
    ## Name of DRS VM-to-VMHost rule to get (or, all if no name specified)
    [Parameter(Position = 0, ParameterSetName="ByName")]
    [string]${Name} = '*',

    ## Cluster from which to get DRS VM-to-VM rule (or, all clusters if no name specified)
    [Parameter(Position = 1, ParameterSetName="ByName", ValueFromPipeline = $True)]
    [PSObject[]]${Cluster},

    ## Virtual Machine for which to get the corresponding VM-to-VM DRS rule(s), if any
    [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByRelatedObject")]
    [VMware.VimAutomation.Types.VirtualMachine]$VM,

    ## Switch:  return DRS VM to VM rule as "raw" VMware.Vim.ClusterAffinityRuleSpec or VMware.Vim.ClusterAntiAffinityRuleSpec object (contains less info, but useful to other functions that can consume this raw object)
    [switch]$ReturnRawRule
  )

  Process {
    ## is this invocation getting item by related object?
    $bByRelatedObject = $PSCmdlet.ParameterSetName -eq "ByRelatedObject"
    ## get cluster object(s) from the Cluster param (if no value was specified -- gets all clusters)
    $arrClustersToCheck = if ($bByRelatedObject) {$VM.VMHost.Parent} else {Get-ClusterObjFromClusterParam -Cluster $Cluster}
    ## for the cluster(s) to check, try to get the pertinent VM-to-VM rules
    $arrClustersToCheck | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach rule item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Rule |
      Where-Object -FilterScript {
        ($_ -is [VMware.Vim.ClusterAffinityRuleSpec] -or $_ -is [VMware.Vim.ClusterAntiAffinityRuleSpec]) -and
        $(if ($bByRelatedObject) {$_.VM -contains $VM.Id} else {$_.Name -like ${Name}})
      } |
      ForEach-Object -Process {
        if ($ReturnRawRule) {$_}
        else{
          New-Object DRSRule_VMToVMRule -Property @{
            Name         = $_.Name
            Cluster      = $oThisCluster.Name
            ClusterId    = $oThisCluster.Id
            Enabled      = [Boolean]$_.Enabled
            KeepTogether = $($_ -is [VMware.Vim.ClusterAffinityRuleSpec])
            VM           = $(
                          if($_.VM) {Get-View $_.VM -Property Name | Select-Object -ExpandProperty Name}
                          else {$null}
                        )
            VMId        = $_.VM
            UserCreated = [Boolean]$_.UserCreated
            Type        = $_.GetType().Name
#            Mandatory   = [Boolean]$_.Mandatory
          }
        }
      }
    }
  }
}


<#  .Description
    This cmdlet retrieves the DRS VM to VMHost rules.
    It returns a number of DRS VM to VMHost rules that correspond to the filter criteria provided by the cmdlet parameters.

    The default return type holds more information than the "raw" DRS object that vSphere uses.  There is also a switch to allow for just returning said raw DRS object, quite useful for consumption by other cmdlets in this module.

    .Synopsis
    Retrieve the DRS VM to VMHost rules

    .Example
    Get-DrsVMToVMHostRule -Name 'Rule 1*'
    Name         Cluster         Enabled     Mandatory   VMGroupName
    ----         -------         -------     ---------   -----------
    Rule 1       Cluster1        False       False       VM Group 1
    Rule 11      Cluster2        True        True        All VM

    Returns all DRS VM to VMHost rules with name like 'Rule 1*'

    .Example
    Get-DrsVMtoVMHostRule -Cluster Cluster[12]
    Name         Cluster         Enabled     Mandatory   VMGroupName
    ----         -------         -------     ---------   -----------
    Rule 0       Cluster1        True        False       VM Group 1
    Rule 1       Cluster1        False       False       VM Group 12
    Rule 2       Cluster1        False       False       VM Group 31
    Rule 11      Cluster2        True        True        All VM
    Rule_bak     Cluster2        True        False       testVMGroup
    Rule_toDel   Cluster2        False       True        VM Group 5

    Returns all DRS VM to VMHost rules in clusters named "Cluster1" and "Cluster2"

    .Example
    Get-VM myVM0 | Get-DrsVMtoVMHostRule
    Name         Cluster         Enabled     Mandatory   VMGroupName
    ----         -------         -------     ---------   -----------
    Rule 2       Cluster1        False       False       VM Group 31

    Returns all DRS VM to VMHost rules in the cluster in which "myVM0" resides that involve a DRS VMGroup of which "myVM0" is a member

    .Example
    Get-VMHost myhost0.dom.com | Get-DrsVMtoVMHostRule
    Name         Cluster         Enabled     Mandatory   VMGroupName
    ----         -------         -------     ---------   -----------
    Rule_toDel   Cluster2        False       True        VM Group 5

    Returns all DRS VM to VMHost rules in the cluster of which VMHost "myhost0.dom.com" is a part, and that involve a DRS VMHostGroup of which "myhost0.dom.com" is a member (either as the Affine or AntiAffine VMHost group)

    .Outputs
    DRSRule_VMToVMHostRule bject with information about the given DRS VM to VMHost rule, or a "raw" VMware.Vim.ClusterVmHostRuleInfo vSphere object

    .Link
    https://github.com/PowerCLIGoodies/DRSRule
    New-DrsVMToVMHostRule
    Remove-DrsVMToVMHostRule
    Set-DrsVMToVMHostRule
#>
function Get-DrsVMToVMHostRule {
  [CmdletBinding(DefaultParameterSetName = "ByName")]
  [OutputType([DRSRule_VMToVMHostRule],[VMware.Vim.ClusterVmHostRuleInfo])]
  param(
    ## Name of DRS VM affinity/antiaffinity rule to get (or, all if no name specified)
    [Parameter(Position = 0, ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [string]${Name} = '*',

    ## Cluster from which to get DRS VM-to-VMhost rule (or, all clusters if no name specified)
    [Parameter(Position = 1, ParameterSetName="ByName", ValueFromPipeline = $True)]
    [PSObject[]]${Cluster},

    ## Virtual Machine for which to get the corresponding VM-to-VMHost DRS rule(s), if any
    [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByRelatedVM")]
    [VMware.VimAutomation.Types.VirtualMachine]$VM,

    ## VMHost for which to get the corresponding VM-to-VMHost DRS rule(s), if any
    [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByRelatedVMHost")]
    [VMware.VimAutomation.Types.VMHost]$VMHost,

    ## Switch:  return DRS VM to VMHost rule as "raw" VMware.Vim.ClusterVmHostRuleInfo object (contains less info, but useful to other functions that can consume this raw object)
    [switch]$ReturnRawRule
  )

  Process {
    ## is this invocation getting item by related object?
    $bByRelatedObject = "ByRelatedVM", "ByRelatedVMHost" -contains $PSCmdlet.ParameterSetName
    ## get cluster object(s) from the Cluster param (if no value was specified -- gets all clusters), and the FilterScript scriptblock to use for the Where-Object call later, for "filtering" rules
    $arrClustersToCheck, $sbFilterScript = if ($bByRelatedObject) {
      if ($PSCmdlet.ParameterSetName -eq "ByRelatedVM") {
        ## the cluster in which the VM resides, and, a scriptblock that checks if the list of names of DRS VMGroups of which this VM is a part contains the VMGroupName property's value in the given VMToVMHost rule
        $VM.VMHost.Parent, {($VM | Get-DrsVMGroup -ReturnRaw).Name -contains $_.VmGroupName}
      } else {
        $arrNamesOfVMHostGroups_thisVMHost = ($VMHost | Get-DrsVMHostGroup -ReturnRaw).Name
        ## the cluster in which the VMHost resides, and, a scriptblock that checks if the list of names of DRS VMHostGroups of which this VMHost is a part contains either the AffineHostGroupName or AffineHostGroupName property's value in the given VMToVMHost rule
        #   good way to do it using Compare-Object, but possibly more confusing to read -- checks to see if there is more than zero "equal" items in the two arrays
        # $VMHost.Parent, {(Compare-Object -ReferenceObject $arrNamesOfVMHostGroups_thisVMHost -DifferenceObject @($_.AffineHostGroupName, $_.AntiAffineHostGroupName) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0}
        $VMHost.Parent, {$arrNamesOfVMHostGroups_thisVMHost -contains $_.AffineHostGroupName -or ($arrNamesOfVMHostGroups_thisVMHost -contains $_.AntiAffineHostGroupName)}
      } ## end else
    } else {(Get-ClusterObjFromClusterParam -Cluster $Cluster), {$_.Name -like $Name}}
    ## for the cluster(s) to check, try to get the pertinent VM-to-VMHost rules
    $arrClustersToCheck | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach rule item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Rule |
      Where-Object -FilterScript {$_ -is [VMware.Vim.ClusterVmHostRuleInfo]} |
      ## filter by the VmGroupName, the VMHostGroupName, or by the rule name, depending on the parameters supplied to this cmdlet call
      Where-Object -FilterScript $sbFilterScript |
      ForEach-Object -Process {
        if ($ReturnRawRule) {$_}
        else {
          New-Object DRSRule_VMToVMHostRule -Property @{
            Name                    = $_.Name
            Cluster                 = $oThisCluster.Name
            ClusterId               = $oThisCluster.Id
            Enabled                 = [Boolean]$_.Enabled
            Mandatory               = [Boolean]$_.Mandatory
            VMGroupName             = $_.vmGroupName
            AffineHostGroupName     = $_.affineHostGroupName
            AntiAffineHostGroupName = $_.antiAffineHostGroupName
            UserCreated             = [Boolean]$_.UserCreated
            Type                    = $_.GetType().Name
          }
        }
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function New-DrsVMGroup {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule_VMGroup])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [Parameter(Mandatory = $True, Position = 2, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a VM obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])
    })]
    [PSObject[]]${VM},

    [Switch]$Force
  )

  Process{
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if group of this name already exists in this cluster; removed the -ReturnRaw, as the actual group is what is needed for removal action later (if appropriate)
      $oExistingVmGroup = Get-DrsVMGroup -Cluster $oThisCluster -Name $Name
      if ($oExistingVmGroup -and !$Force) {
        Throw "DRS VM group named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingVmGroup -and $Force) {
        ## changed to use item returned from Get-DrsVMGroup, instead of "$_", which was the cluster object
        $oExistingVmGroup | Remove-DrsVMGroup
      }
      else {
        Write-Verbose "Good -- no DRS group of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      $VM = $VM | Foreach-Object {
        $oThisVmItem = $_
        if($oThisVmItem -is [System.String]) {
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VM -Name $oThisVmItem -ErrorAction:Stop
          }
          catch {Write-Warning "No VM of name '$oThisVmItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"; Throw $_}
        }
        else {
          $oThisVmItem
        }
      }
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create DRS VM group '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $newGroup = New-Object VMware.Vim.ClusterVmGroup
        $newGroup.Name = ${Name}
        $newGroup.UserCreated = $True
        ## changed to use .Id instead of .ExtensionData.MoRef, for speed's sake (doesn't need to populate VM objects' .ExtensionData)
        $newGroup.VM = ${VM} | ForEach-Object -Process {$_.Id}
        $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
        $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::Add
        $groupSpec.Info = $newGroup
        $spec.GroupSpec += $groupSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)

        Get-DrsVMGroup -Cluster $oThisCluster -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function New-DrsVMHostGroup {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule_VMHostGroup])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [Parameter(Mandatory = $True, Position = 2, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a VMHost obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost])
    })]
    [PSObject[]]${VMHost},

    [Switch]$Force
  )

  Process{
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if group of this name already exists in this cluster
      $oExistingVMHostGroup = Get-DrsVMHostGroup -Cluster $oThisCluster -Name $Name
      if ($oExistingVMHostGroup -and !$Force) {
        Throw "DRS VMHost group named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingVMHostGroup -and $Force) {
        $oExistingVMHostGroup | Remove-DrsVMHostGroup
      }
      else {
        Write-Verbose "Good -- no DRS group of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      $VMHost = $VMHost | Foreach-Object {
        $oThisVMHostItem = $_
        if($oThisVMHostItem -is [System.String]) {
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VMHost -Name $oThisVMHostItem -ErrorAction:Stop
          }
          catch {Write-Warning "No VMHost of name '$oThisVMHostItem' found in cluster '$($oThisCluster.Name)'. Valid VMHost name?"; Throw $_}
        }
        else {
          $oThisVMHostItem
        }
      }
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create DRS VMHost group '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $newGroup = New-Object VMware.Vim.ClusterHostGroup
        $newGroup.Name = ${Name}
        $newGroup.UserCreated = $True
        $newGroup.Host = ${VMHost} | ForEach-Object -Process {$_.Id}
        $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
        $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::Add
        $groupSpec.Info = $newGroup
        $spec.GroupSpec += $groupSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)

        Get-DrsVMHostGroup -Cluster $oThisCluster -Name ${Name}
      }
    }
  }
}


#.ExternalHelp DRSRule.Help.xml
Function New-DrsVMToVMHostRule {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule_VMToVMHostRule])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [switch]${Enabled},

    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [switch]${Mandatory},

    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [String]${VMGroupName},

    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [String]${AffineHostGroupName},

    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [String]${AntiAffineHostGroupName},

    [Switch]$Force
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if rule of this name already exists in this cluster
      $oExistingRule = Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name $Name
      if ($oExistingRule -and !$Force) {
        Throw "DRS rule named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingRule -and $Force) {
        $oExistingRule | Remove-DrsVMToVMHostRule
      }
      else {
        Write-Verbose "Good -- no DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      ## check if VMGroupName and AffineHostGroupName/AntiAffineHostGroupName (the one specified) are valid groups in this cluster
      if ($null -eq (Get-DrsVMGroup -Cluster $oThisCluster -Name $VMGroupName)) {Throw "No DrsVmGroup named '$VMGroupName' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVmGroup '$VMGroupName' found in cluster '$($oThisCluster.Name)'"}

      $strDrsVMHostGroupNameToCheck = ${AffineHostGroupName},${AntiAffineHostGroupName} | Where-Object {-not [String]::IsNullOrEmpty($_)}
      if(!$strDrsVMHostGroupNameToCheck) {
        Throw "No VMHostGroup specified for new rule on cluster $($oThisCluster.Name)"
      }
      if ($null -eq (Get-DrsVMHostGroup -Cluster $oThisCluster -Name $strDrsVMHostGroupNameToCheck)) {Throw "No DrsVMHostGroup named '$strDrsVMHostGroupNameToCheck' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVMHostGroup '$strDrsVMHostGroupNameToCheck' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create $(if ([String]::IsNullOrEmpty(${AffineHostGroupName})) {'AntiAffineVMToVMHost'} else {'AffineVMToVMHost'}) DRS rule '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx

        $newRule = New-Object VMware.Vim.ClusterVmHostRuleInfo
        $newRule.Name = ${Name}
        $newRule.Mandatory = ${Mandatory}
        $newRule.Enabled = ${Enabled}
        $newRule.UserCreated = $True
        $newRule.VmGroupName = ${VMGroupName}
        $newRule.AffineHostGroupName = ${AffineHostGroupName}
        $newRule.AntiAffineHostGroupName = ${AntiAffineHostGroupName}

        $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
        $ruleSpec.Info = $newRule

        $spec.RulesSpec += $ruleSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)

        Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function New-DrsVMToVMRule {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule_VMToVMRule])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [switch]${Enabled},

#    [Parameter(ValueFromPipelineByPropertyName=$True)]
#    [ValidateNotNullOrEmpty()]
#    [switch]${Mandatory},
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [switch]${KeepTogether},

    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a VM obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])
    })]
    [PSObject[]]${VM},

    [Switch]$Force
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if rule of this name already exists in this cluster
      $oExistingRule = Get-DrsVMtoVMRule -Cluster $oThisCluster -Name $Name
      if ($oExistingRule -and !$Force) {
        Throw "DRS rule named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingRule -and $Force) {
        $oExistingRule | Remove-DrsVMToVMRule
      }
      else {
        Write-Verbose "Good -- no DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      $VM = $VM | Foreach-Object {
        $oThisVmItem = $_
        if($oThisVmItem -is [System.String]) {
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VM -Name $oThisVmItem -ErrorAction:Stop
          }
          catch {Write-Warning "No VM of name '$oThisVmItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"; Throw $_}
        }
        else {
          $oThisVmItem
        }
      }
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create DRS VM $(if (${KeepTogether}) {'KeepTogether'} else {'KeepApart'}) rule '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx

        $newRule = $(
          if(${KeepTogether}) {New-Object VMware.Vim.ClusterAffinityRuleSpec}
          else {New-Object VMware.Vim.ClusterAntiAffinityRuleSpec}
        )
        $newRule.Name        = ${Name}
        $newRule.Enabled     = [Boolean]${Enabled}
#        $newRule.Mandatory   = [Boolean]${Mandatory}
        $newRule.UserCreated = $True
        $newRule.Vm          = $VM | Foreach-Object {$_.Id}
        $ruleSpec            = New-Object VMware.Vim.ClusterRuleSpec
        $ruleSpec.Info       = $newRule

        $spec.RulesSpec += $ruleSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)

        Get-DrsVMtoVMRule -Cluster $oThisCluster -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Remove-DrsVMGroup {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::High)]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster}
  )

  Process {
   Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## check that VMGroup exists
      $target = @(Get-DrsVMGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup)
      if ($null -eq $target) {Throw "No DrsVmGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVmGroup '$Name' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS VM group '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | Foreach-Object {
          $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
          $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::remove
          $groupSpec.RemoveKey = $_.Name
          $groupSpec.Info = $_
          $spec.GroupSpec += $groupSpec
        }

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Remove-DrsVMHostGroup {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::High)]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster}
  )

  Process{
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## check that VMHostGroup exists
      $target = @(Get-DrsVMHostGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup)
      if ($null -eq $target) {Throw "No DrsVMHostGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVMHostGroup '$Name' found in cluster '$($oThisCluster.Name)'"}
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS Host group '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | Foreach-Object {
          $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
          $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::remove
          $groupSpec.RemoveKey = $_.Name
          $groupSpec.Info = $_
          $spec.GroupSpec += $groupSpec
        }

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Remove-DrsVMToVMHostRule {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::High)]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster}
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## verify that rule of this name exists in this cluster
      $target = @(Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule)
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS rule '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | Foreach-Object {
          $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
          $ruleSpec.Info = $_
          $ruleSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::remove
          ## this RemoveKey needs the .Key property of the rule object, not the .Name property in other RemoveKey examples
          $ruleSpec.RemoveKey = $_.Key
          $spec.RulesSpec += $ruleSpec
        }

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Remove-DrsVMToVMRule {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::High)]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster}
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## verify that rule of this name exists in this cluster
      $target = @(Get-DrsVMtoVMRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule)
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS rule '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | ForEach-Object {
          $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
          $ruleSpec.Info = $_
          $ruleSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::remove
          ## this RemoveKey needs the .Key property of the rule object, not the .Name property in other RemoveKey examples
          $ruleSpec.RemoveKey = $_.Key
          $spec.RulesSpec += $ruleSpec
        }

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
      }
    }
  }
}


<#  .Description
    This cmdlet changes settings of the DRS VM group with the provided parameters

    .Synopsis
    Cmdlet to change a DRS VM group

    .Example
    Get-DrsVMGroup -Name 'VM Group 1' -Cluster Cluster1 | Set-DrsVMGroup -AddVM vm3
    Add the given virtual machine to DRS VM group 'VM Group 1' on cluster 'Cluster1'
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    VM Group 1         Cluster1        False              {VM1,VM2,VM3}

    .Example
    Set-DrsVMGroup -Name 'VM Group 1' -Append -VM vm4 -Cluster Cluster1
    Add the given virtual machine to DRS VM group 'VM Group 1' on cluster 'Cluster1'. This is the same functionality as provided by the more recently added -AddVM parameter, but is being kept in place in order to remain backwards compatible with existing scripts out there.
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    VM Group 1         Cluster1        False              {VM1,VM2,VM3,VM4}

    .Example
    Get-DrsVMGroup -Name 'VM Group 1' -Cluster Cluster1 | Set-DrsVMGroup -RemoveVM vm[1-2]
    Remove the given virtual machines from DRS VM group 'VM Group 1' on cluster 'Cluster1'
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    VM Group 1         Cluster1        False              {VM3,VM4}

    .Outputs
    DRSRule_VMGroup object with information about the updated DRS VM group

    .Link
    https://github.com/PowerCLIGoodies/DRSRule
    Get-DrsVMGroup
    New-DrsVMGroup
    Remove-DrsVMGroup
#>
function Set-DrsVMGroup {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium, DefaultParameterSetName = "ByVMParam")]
  [OutputType([DRSRule_VMGroup])]
  param (
    ## The name of the DRS VM group to modify
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    ## Cluster in which the DRS VM group resides
    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]$Cluster,

    ## VM(s) to add to the DRS VM group. The VMs can be specified as strings (their names) or as VirtualMachine objects.
    [parameter(Mandatory = $True, ParameterSetName="AddVM")]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])
    })]$AddVM,

    ## VM(s) to remove from the DRS VM group. The VMs can be specified as strings (their names) or as VirtualMachine objects.
    [parameter(Mandatory = $True, ParameterSetName="RemoveVM")]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])
    })]$RemoveVM,

    ## The VM that shall be in the DRS VM group. The VMs can be specified as strings (their names) or as VirtualMachine objects. Without the -Append parameter, this -VM parameter essentially overwrites the existing list of VMGroup members with the VMs specified.
    #
    ## The -VM parameter, when used with the -Append parameter, provides the same functionality as the more recently added -AddVM parameter.  The -VM and -Append parameters are being kept as-is so as to maintain backwards compatibility with existing scripts.
    [parameter(ValueFromPipeline=$true, ParameterSetName="ByVMParam")]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])
    })]
    [PSObject[]]$VM,

    ## Switch: append the given VM(s) as members of the DRS VM group ($true), or set them as the only members of the group ($false or not specified)?  Not used with -AddVM or -RemoveVM parameters.
    [parameter(ParameterSetName="ByVMParam")][Switch]$Append
  ) ## end param

  Process {
   Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_

      ## the VM names/object to consider when setting this DRS VM group, based on the parameter set in play
      $arrVMInputToConsider = Switch ($PsCmdlet.ParameterSetName) {
        "ByVMParam" {$VM; break}
        "AddVM" {$AddVM; break}
        "RemoveVM" {$RemoveVM}
      } ## end switch

      ## the actual VM objects to use for the VMGroup update
      $arrVMsForGroupUpdate = $arrVMInputToConsider | Foreach-Object {
        $oThisVmItem = $_
        if ($_ -is [System.String]) {
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VM -Name $oThisVmItem -ErrorAction:Stop
          }
          catch {Write-Warning "No VM of name '$oThisVmItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"; Throw $_}
        }
        else {
          $oThisVmItem
        }
      } ## end foreach-object

      ## check that VMGroup exists
      $target = Get-DrsVMGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup
      if ($null -eq $target) {Throw "No DrsVmGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVmGroup '$Name' found in cluster '$($oThisCluster.Name)'"}
      if ($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS VM group '$Name'")) {
        ## the IDs of the VMs of interest for this group update (will be added to-, removed from-, or will replace the existing VMGroup members)
        $arrMembersIdsOfInterest = $arrVMsForGroupUpdate | ForEach-Object -Process {$_.Id}

        ## new cluster config spec
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
        $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit
        ## original VM IDs that were in the VMGroup (for later comparison)
        $arrOriginalVMIDsInTarget = $target.VM
        $groupSpec.Info = $target

        ## set the members of the group according to the parameterset
        Switch ($PsCmdlet.ParameterSetName) {
          "ByVMParam" {
            if ($Append) {$groupSpec.Info.VM += $arrMembersIdsOfInterest | Where-Object {$groupSpec.Info.VM -notcontains $_}}
            else {$groupSpec.Info.VM = $arrMembersIdsOfInterest}
            break
          } ## end case
          ## just add the given VM IDs (same as -Append param with -VM param, which were kept for backwards compatibility)
          "AddVM" {$groupSpec.Info.VM += $arrMembersIdsOfInterest | Where-Object {$groupSpec.Info.VM -notcontains $_}; break}
          ## remove the given VM IDs from the spec
          "RemoveVM" {
            ## if the none of the specified VMs are already a part of the group, write a verbose message to that effect
            if ((Compare-Object -ReferenceObject $groupSpec.Info.VM -DifferenceObject $arrMembersIdsOfInterest -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0) {
                Write-Verbose "None of the VMs specified are in VMGroup '$($target.Name)' -- no VMs will be removed from group"
            } ## end if
            ## else, just "keep" the VM IDs that were not specified to be removed
            else {$groupSpec.Info.VM = $groupSpec.Info.VM | Where-Object {$arrMembersIdsOfInterest -notcontains $_}}
          } ## end case
        } ## end switch

        ## if all VMs were specified to be remove from the group (if the $groupSpec.Info.VM value is $null), write warning and take no further action (may not be supported by vSphere API, seemingly; trying to do so via GUI returns message to the effect of, "Cannot remove all members of group")
        if ($null -eq $groupSpec.Info.VM) {Write-Warning "Removing all VMs from VMGroup not supported. Taking no action"}
        ## if the VMGroup had any VMs in it already, and the VM list is the same between the existing VMGroup and the new ClusterGroupSpec, do not bother calling ReconfigureComputeResource() method
        elseif (($null -ne $arrOriginalVMIDsInTarget) -and $null -eq (Compare-Object -ReferenceObject $arrOriginalVMIDsInTarget -DifferenceObject $groupSpec.Info.VM)) {
            Write-Verbose "Not changing VMGroup (no new members added, and no members to remove)"
        } ## end if
        else {
          $spec.GroupSpec += $groupSpec
          $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
          ## return the updated object
          Get-DrsVMGroup -Cluster $Cluster -Name $Name
        } ## end else

      } ## end if shouldprocess
    } ## end foreach-object
  } ## end process
} ## end fn


<#  .Description
    This cmdlet changes settings of the DRS VMHost group with the provided parameters

    .Synopsis
    Changes a DRS VMHost group

    .Example
    Get-DrsVMHostGroup -Name 'My ESX' -Cluster Cluster1 | Set-DrsVMHostGroup -AddVMHost esx3
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    My ESX             Cluster1        True               {esx1,esx2,esx3}

    .Example
    Set-DrsVMHostGroup -Name 'My ESX' -Append -VMHost esx4 -Cluster Cluster1
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    My ESX             Cluster1        True               {esx1,esx2,esx3,esx4}

    .Example
    Get-DrsVMHostGroup -Name 'My ESX' -Cluster Cluster1 | Set-DrsVMHostGroup -RemoveVMHost esx[1-2]
    Name               Cluster         UserCreated        VM
    ----               -------         -----------        --
    My ESX             Cluster1        True               {esx3,esx4}

    .Outputs
    DRSRule_VMHostGroup object with information about the updated DRS VMHost group

    .Link
    https://github.com/PowerCLIGoodies/DRSRule
    Get-DrsVMHostGroup
    New-DrsVMHostGroup
    Remove-DrsVMHostGroup
#>
function Set-DrsVMHostGroup {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium, DefaultParameterSetName = "ByVMHostParam")]
  [OutputType([DRSRule_VMHostGroup])]
  param (
    ## The name of the DRS VMHost group to modify
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    ## Cluster in which the DRS VMHost group resides
    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]$Cluster,

    ## VMHost(s) to add to the DRS VMHost group. The VMHosts can be specified as strings (their names) or as VMHost objects.
    [parameter(Mandatory = $True, ParameterSetName="AddVMHost")]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost])
    })]$AddVMHost,

    ## VMHost(s) to remove from the DRS VMHost group. The VMHosts can be specified as strings (their names) or as VMHost objects.
    [parameter(ValueFromPipeline=$true, ParameterSetName="RemoveVMHost")]
    [ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost])
    })]$RemoveVMHost,

    ## The VMHost that shall be in the DRS VMHost group. The VMHost can be given as strings (names) or as VMHost objects. Without the -Append parameter, this -VMHost parameter essentially overwrites the existing list of VMHostGroup members with the VMHosts specified.
    #
    ## The -VMHost parameter, when used with the -Append parameter, provides the same functionality as the more recently added -AddVMHost parameter.  The -VMHost and -Append parameters are being kept as-is so as to maintain backwards compatibility with existing scripts.
    [parameter(Mandatory=$true, ParameterSetName="ByVMHostParam")][ValidateNotNullOrEmpty()][ValidateScript({
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost])
    })]
    [PSObject[]]$VMHost,

    ## Switch: append the given VMHosts(s) as members of the DRS VMHost group ($true), or set them as the only members of the group ($false or not specified)?  Not used with -AddVMHost or -RemoveVMHost parameters.
    [parameter(ParameterSetName="ByVMHostParam")][Switch]$Append
  ) ## end param

  process {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_

      ## the VM names/object to consider when setting this DRS VM group, based on the parameter set in play
      $arrVMHostInputToConsider = Switch ($PsCmdlet.ParameterSetName) {
        "ByVMHostParam" {$VMHost; break}
        "AddVMHost" {$AddVMHost; break}
        "RemoveVMHost" {$RemoveVMHost}
      } ## end switch

      ## the actual VMHost objects to use for the VMHostGroup update
      $arrVMHostsForGroupUpdate = $arrVMHostInputToConsider | Foreach-Object {
        $oThisVMHostItem = $_
        if ($_ -is [System.String]) {
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VMHost -Name $oThisVMHostItem -ErrorAction:Stop
          }
          catch {Write-Warning "No VMHost of name '$oThisVMHostItem' found in cluster '$($oThisCluster.Name)'. Valid VMHost name?"; Throw $_}
        }
        else {
          $oThisVMHostItem
        }
      } ## end foreach-object

      ## if no matching VMHosts found in cluster
      if ($null -eq $arrVMHostsForGroupUpdate) {Write-Warning "No matching VMHosts found in cluster for group update. Valid VMHost? ('$($arrVMHostInputToConsider -join ', ')')"}
      else {
        ## check that VMHostGroup exists
        $target = Get-DrsVMHostGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup
        if ($null -eq $target) {Throw "No DrsVMHostGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
        else {Write-Verbose "DrsVMHostGroup '$Name' found in cluster '$($oThisCluster.Name)'"}
        if ($PsCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS Host group '$Name'")) {
          ## the IDs of the VMHosts of interest for this group update (will be added to-, removed from-, or will replace the existing VMGroup members)
          $arrMembersIdsOfInterest = $arrVMHostsForGroupUpdate | ForEach-Object -Process {$_.Id}

          ## new cluster config spec
          $spec = New-Object VMware.Vim.ClusterConfigSpecEx
          $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
          $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit
          ## original VM IDs that were in the VMGroup (for later comparison)
          $arrOriginalVMHostIDsInTarget = $target.Host
          $groupSpec.Info = $target

          ## set the members of the group according to the parameterset
          Switch ($PsCmdlet.ParameterSetName) {
            "ByVMHostParam" {
              if ($Append) {$groupSpec.Info.Host += $arrMembersIdsOfInterest | Where-Object {$groupSpec.Info.Host -notcontains $_}}
              else {$groupSpec.Info.Host = $arrMembersIdsOfInterest}
              break
            } ## end case
            ## just add the given VMHost IDs (same as -Append param with -VMHost param, which were kept for backwards compatibility)
            "AddVMHost" {$groupSpec.Info.Host += $arrMembersIdsOfInterest | Where-Object {$groupSpec.Info.Host -notcontains $_}; break}
            ## remove the given VMHost IDs from the spec
            "RemoveVMHost" {
              ## if the none of the specified VMHosts are already a part of the group, write a verbose message to that effect
              if ((Compare-Object -ReferenceObject $groupSpec.Info.Host -DifferenceObject $arrMembersIdsOfInterest -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0) {
                  Write-Verbose "None of the VMHosts specified are in VMHostGroup '$($target.Name)' -- no VMHosts will be removed from group"
              } ## end if
              ## else, just "keep" the VMHost IDs that were not specified to be removed
              else {$groupSpec.Info.Host = $groupSpec.Info.Host | Where-Object {$arrMembersIdsOfInterest -notcontains $_}}
            } ## end case
          } ## end switch

          ## if all hosts were specified to be remove from the group (if the $groupSpec.Info.Host value is $null), write warning and take no further action (may not be supported by vSphere API, seemingly; trying to do so via GUI returns message to the effect of, "Cannot remove all members of group")
          if ($null -eq $groupSpec.Info.Host) {Write-Warning "Removing all VMHosts from VMHostGroup not supported. Taking no action"}
          ## if there were hosts in the group to start, and the VMHost list is the same between the existing VMHostGroup and the new ClusterGroupSpec, do not bother calling ReconfigureComputeResource() method
          elseif (($null -ne $arrOriginalVMHostIDsInTarget) -and ($null -eq (Compare-Object -ReferenceObject $arrOriginalVMHostIDsInTarget -DifferenceObject $groupSpec.Info.Host))) {
              Write-Verbose "Not changing VMHostGroup (no new members added, and no members to remove)"
          } ## end if
          else {
            $spec.GroupSpec += $groupSpec
            $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
            ## return the updated object
            Get-DrsVMHostGroup -Cluster $Cluster -Name $Name
          } ## end else

        } ## end if shouldprocess
      } ## end foreach-object
    } ## end else
  } ## end process
} ## end fn


#.ExternalHelp DRSRule.Help.xml
Function Set-DrsVMToVMHostRule {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule_VMToVMHostRule])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Position = 1, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [switch]${Enabled},

    [PSObject]${VMGroup},

    [PSObject]${VMHostGroup},

    [switch]${Mandatory},

    [switch]${KeepTogether}
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if VMGroup and VMHostGroup (if specified) are valid groups in this cluster
      if($PSBoundParameters.ContainsKey("VMGroup")) {
        if ($null -eq (Get-DrsVMGroup -Cluster $oThisCluster -Name $VMGroup)) {Throw "No DrsVmGroup named '$VMGroup' in cluster '$($oThisCluster.Name)'. Valid group name?"}
        else {Write-Verbose "DrsVmGroup '$VMGroup' found in cluster '$($oThisCluster.Name)'"}
      }
      if($PSBoundParameters.ContainsKey("VMHostGroup")) {
        if ($null -eq (Get-DrsVMHostGroup -Cluster $oThisCluster -Name $VMHostGroup)) {Throw "No DrsVMHostGroup named '$VMHostGroup' in cluster '$($oThisCluster.Name)'. Valid group name?"}
        else {Write-Verbose "DrsVMHostGroup '$VMHostGroup' found in cluster '$($oThisCluster.Name)'"}
      }

      ## verify that rule of this name exists in this cluster
      $target = Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS rule '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
        $ruleSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit
        $ruleSpec.Info = $target
        if($PSBoundParameters.ContainsKey("Enabled")) {
          $ruleSpec.Info.Enabled = ${Enabled}
        }
        if($null -ne ${VMGroup}) {
          $ruleSpec.Info.VmGroupName = ${VMGroup}
        }
        if($PSBoundParameters.ContainsKey("Mandatory")) {
          $ruleSpec.Info.Mandatory = ${Mandatory}
        }
        ## if -KeepTogether param passed
        if ($PSBoundParameters.ContainsKey("KeepTogether")) {
          ## if KeepTogether is $true, set affinehostgroupname to either -VMHostGroup if specified or the HostGroup name that was already either affine or antiaffine in target rule
          if ($KeepTogether) {
            $ruleSpec.Info.AffineHostGroupName = $(
              if ($null -ne ${VMHostGroup}) {${VMHostGroup}}
              else {$target.AffineHostGroupName, $target.AntiAffineHostGroupName | Where-Object {-not [String]::IsNullOrEmpty($_)}}
            )
            $ruleSpec.Info.AntiAffineHostGroupName = $null
          }
          ## else set ANTIaffinehostgroupname to either -VMHostGroup if specified or the HostGroup name that was already either affine or antiaffine in target rule
          else {
            ## order matters here, as $ruleSpec.Info is a reference to $target; so, need to use the values before setting AffineHostGroupName property to $null
            $ruleSpec.Info.AntiAffineHostGroupName = $(
              if ($null -ne ${VMHostGroup}) {${VMHostGroup}}
              else {$target.AffineHostGroupName, $target.AntiAffineHostGroupName | Where-Object {-not [String]::IsNullOrEmpty($_)}}
            $ruleSpec.Info.AffineHostGroupName = $null
            )
          }
        }
        ## if -VMHostGroup param passed _without_ -KeepTogether param
        elseif ($PSBoundParameters.ContainsKey("VMHostGroup")) {
          ## if this was a VM-to-Host _affinity_ rule already, set the affine group to the new value
          if ($null -ne $target.AffineHostGroupName) {
            $ruleSpec.Info.AffineHostGroupName = ${VMHostGroup}
            $ruleSpec.Info.AntiAffineHostGroupName = $null
          }
          ## else, set the antiaffine group to the new value
          else {
            $ruleSpec.Info.AffineHostGroupName = $null
            $ruleSpec.Info.AntiAffineHostGroupName = ${VMHostGroup}
          }
        }
        $spec.RulesSpec += $ruleSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
        Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Set-DrsVMToVMRule {
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule_VMToVMRule])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},

    [Parameter(Position = 1, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [switch]${Enabled},

    [switch]${Mandatory},

    [switch]${KeepTogether},

    [PSObject[]]${VM},

    [Switch]${Append}
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## verify that rule of this name exists in this cluster
      $target = Get-DrsVMtoVMRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}

      ## verify that VM exists
      if($PSBoundParameters.ContainsKey("VM")) {
        $VM = $VM | Foreach-Object {
          $oThisVMItem = $_
          if($_ -is [System.String]){
            try {
              ## limit scope to this cluster
              $oThisCluster | Get-VM -Name $oThisVMItem -ErrorAction:Stop
            }
            catch {Write-Warning "No VM of name '$oThisVMItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"; Throw $_}
          }
          else {
            $oThisVMItem
          }
        }
      }

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS rule '${Name}'")) {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
        $ruleSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit

        ## Check if -KeepTogether param passed
        $ruleSpec.Info = $(
          if($PSBoundParameters.ContainsKey('KeepTogether')) {
            if(${KeepTogether}) {
              if($target -is [VMware.Vim.ClusterAffinityRuleSpec]){$target}
              else{
                New-Object VMware.Vim.ClusterAffinityRuleSpec -Property @{
                  Enabled = $target.Enabled
                  VM = $target.VM
                  Key = $target.Key
                  Name = $target.Name
                  UserCreated = $target.UserCreated
                }
              }
            }
            else {
              if($target -is [VMware.Vim.ClusterAntiAffinityRuleSpec]){$target}
              else{
                New-Object VMware.Vim.ClusterAntiAffinityRuleSpec -Property @{
                  Enabled = $target.Enabled
                  VM = $target.VM
                  Key = $target.Key
                  Name = $target.Name
                  UserCreated = $target.UserCreated
                }
              }
            }
          }
          else {
            $target
          }
        )

        ## Enabled switch
        if($PSBoundParameters.ContainsKey("Enabled")) {
          $ruleSpec.Info.Enabled = ${Enabled}
        }
        if($PSBoundParameters.ContainsKey("Mandatory")) {$ruleSpec.Info.Mandatory = ${Mandatory}
        }
        ## VM passed
        if($PSBoundParameters.ContainsKey("VM")) {
          if(${Append}) {
            $ruleSpec.Info.VM = $ruleSpec.Info.VM + $($VM | Foreach-Object {$_.Id})
          }
          else {
            $ruleSpec.Info.VM = $($VM | Foreach-Object {$_.Id})
          }
        }

        $spec.RulesSpec += $ruleSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)
        Get-DrsVMtoVMRule -Cluster $oThisCluster -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Export-DrsRule {
  [CmdletBinding()]
  [OutputType([System.IO.FileInfo])]
  param(
    [Parameter(Position = 0)]
    [string]${Name} ='*',

    [Parameter(Position = 1, ValueFromPipeline = $True)][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},

    [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
    [String]${Path}
  )

  Process {
    $hshParamsForGetCall = @{Name = ${Name}}
    if ($PSBoundParameters.ContainsKey("Cluster")) {$hshParamsForGetCall["Cluster"] = ${Cluster}}
    ## had to make the first items an array of values to pass to the pipeline; else, if the first item was $null, the pipeline seemed to halt, and there were no results, even if one of the other three Get-* calls returned items
    $strDrsRuleInfo_inJSON = @(
       (Get-DrsVMtoVMRule @hshParamsForGetCall),
       (Get-DrsVMtoVMHostRule @hshParamsForGetCall),
       (Get-DrsVMGroup @hshParamsForGetCall),
       (Get-DrsVMHostGroup @hshParamsForGetCall)
      ) | Where-Object {$null -ne $_} |
      ## for each of these items (which may be arrays), put the array's objects on the pipeline for ConvertTo-Json; else, the arrays are exported in the JSON as the parent properties of all of the objects exported (makes arrays with properties "value" and "count", and the actual rule/group objects' JSON is a sub-property of the "value" property)
      Foreach-Object {$_} |
      ConvertTo-Json -Depth 2

    if ($null -ne $strDrsRuleInfo_inJSON) {
      Set-Content -Path ${Path} -Value $strDrsRuleInfo_inJSON
      if ($PSBoundParameters.ContainsKey("Verbose")) {
        ## get num rules in JSON file; using .Length property of the resulting item, as it is a System.Object[] object, and behaves like a hashtable (would need to use .GetEnumerator() to get the items within it)
        $intNumRulesFromJSON = (ConvertFrom-Json -InputObject (Get-Content -Path ${Path} | Out-String)).Length
        Write-Verbose ("Exported and saved information for '{0}' DRS rule{1}/group{1} to '${Path}'" -f $intNumRulesFromJSON, $(if ($intNumRulesFromJSON -ne 1) {"s"}))
      }
      Get-Item ${Path}
    }
    else {$strForVerbose = $(if ($null -eq $Cluster) {"any cluster"} else {"cluster with name like '$Cluster'"}); Write-Verbose "No DRS group/rule found for like name '$Name' in $strForVerbose"}
  }
}

#.ExternalHelp DRSRule_Help.xml
Function Import-DrsRule {
  [CmdletBinding(SupportsShouldProcess=$true)]
  [OutputType([DRSRule_VMGroup],[DRSRule_VMHostGroup],[DRSRule_VMToVMRule],[DRSRule_VMToVMHostRule])]
  param(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})][String]${Path},

    [Parameter(Position = 1)]
    [string]${Name},

    [Parameter(Position = 2, ValueFromPipeline = $True)][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster} = "*",

    [Switch]$Force,

    [Switch]$ShowOnly
  )
  begin {$ruleObjects = (ConvertFrom-Json -InputObject (Get-Content -Path ${Path} | Out-String))}

  Process
  {
    $Cluster | Foreach-Object {
      ## this cluster name (could contain wildcard)
      $strThisClusterName = $(
        if ($_ -is [VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]) {$_.Name}
        else {$_}
      )

      ## the rule objects for clusters whose names are like $strThisClusterName
      $arrRuleObjects_filtered = $ruleObjects.GetEnumerator() | Where-Object -FilterScript {$_.Cluster -like $strThisClusterName}
      ## if -Name was specified, filter
      if ($PSBoundParameters.ContainsKey("Name")) {$arrRuleObjects_filtered = $arrRuleObjects_filtered | Where-Object -FilterScript {$_.Name -like $Name}}
      ## if just showing the matching rules/groups found in .json file, just return the info objects
      if ($ShowOnly) {$arrRuleObjects_filtered}
      ## else, proceed with rule/group creation
      else {
        ## make string messages for ShouldProcess output
        $strClusterInfoForShouldProcessMsg = if ($PSBoundParameters.ContainsKey("Cluster")) {"clusters with name like '$strThisClusterName'"} else {"all clusters with rules/groups in exported JSON file '${Path}'"}
        $strActionInfoForShouldProcessMsg = $($intNumRulesAfterFiltering = ($arrRuleObjects_filtered | Measure-Object).Count; "Recreate '$intNumRulesAfterFiltering' DRS group{0}/rule{0}" -f $(if ($intNumRulesAfterFiltering -ne 1) {"s"}))
        ## create the groups/rules
        if ($PSCmdlet.ShouldProcess($strClusterInfoForShouldProcessMsg, $strActionInfoForShouldProcessMsg)) {
          $arrRuleObjects_filtered | Get-DrsRuleObject -Type 'ClusterVmGroup' | New-DrsVmGroup -Force:$Force
          $arrRuleObjects_filtered | Get-DrsRuleObject -Type 'ClusterHostGroup' | New-DrsVMHostGroup -Force:$Force
          $arrRuleObjects_filtered | Get-DrsRuleObject -Type 'ClusterVmHostRuleInfo' | New-DrsVMtoVMHostRule -Force:$Force
          $arrRuleObjects_filtered | Get-DrsRuleObject -Type 'ClusterAffinityRuleSpec|ClusterAntiAffinityRuleSpec' | New-DrsVMtoVMRule -Force:$Force
        }
      }
    }
  }
}


# Fix for ScriptsToProcess bug in the module manifest
# See Connect Id 903654
# Workaround #2 (credit to Ronald Rink)
[string] $ManifestFile = '{0}.psd1' -f (Get-Item $PSCommandPath).BaseName
$ManifestPathAndFile = Join-Path -Path $PSScriptRoot -ChildPath $ManifestFile
if(Test-Path -Path $ManifestPathAndFile) {
  $Manifest = (Get-Content -raw $ManifestPathAndFile) | Invoke-Expression
  foreach( $ScriptToProcess in $Manifest.ScriptsToProcess) {
    $ModuleToRemove = (Get-Item (Join-Path -Path $PSScriptRoot -ChildPath $ScriptToProcess)).BaseName
    if(Get-Module $ModuleToRemove) {
      Remove-Module $ModuleToRemove
    }
  }
}
