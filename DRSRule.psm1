#.ExternalHelp DRSRule.Help.xml
Function Get-DrsVMGroup
{
  [CmdletBinding()]
  [OutputType([DRSRule.VMGroup],[VMware.Vim.ClusterVmGroup])]
  param(
    [Parameter(Position = 0)]
    [string]${Name} = '*',
    [Parameter(Position = 1, ValueFromPipeline = $True)]
    [PSObject[]]${Cluster},
    [switch]$ReturnRawGroup
  )

  Process{
    ## get cluster object(s) from the Cluster param (if no value was specified -- gets all clusters)
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach ClusterVmGroup item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Group |
      Where-Object -FilterScript {
        ## changed to "like" from "match" -- "*" with -match causes error, as it is expecting regex, not just std wildcard
        ($_ -is [VMware.Vim.ClusterVmGroup]) -and ($_.Name -like ${Name})
      } |
      ForEach-Object -Process {
        if ($true -eq $ReturnRawGroup) {return $_}
        else {
          New-Object -TypeName DRSRule.VMGroup -Property @{
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

#.ExternalHelp DRSRule.Help.xml
Function Get-DrsVMHostGroup
{
  [CmdletBinding()]
  [OutputType([DRSRule.VMHostGroup],[VMware.Vim.ClusterHostGroup])]
  param(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]${Name} = '*',
    [Parameter(Position = 1, ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]${Cluster},
    [switch]$ReturnRawGroup
  )

  Process{
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach ClusterVmGroup item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Group |
      Where-Object -FilterScript {
        ($_ -is [VMware.Vim.ClusterHostGroup]) -and ($_.Name -like ${Name})
      } |
      ForEach-Object -Process {
        if ($true -eq $ReturnRawGroup) {return $_}
        else {
          New-Object DRSRule.VMHostGroup -Property @{
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

#.ExternalHelp DRSRule.Help.xml
Function Get-DrsVMToVMRule
{
  [CmdletBinding()]
  [OutputType([DRSRule.VMToVMRule],[VMware.Vim.ClusterAffinityRuleSpec],[VMware.Vim.ClusterAntiAffinityRuleSpec])]
  param(
    [Parameter(Position = 0)]
    [string]${Name} = '*',
    [Parameter(Position = 1, ValueFromPipeline = $True)]
    [PSObject[]]${Cluster},
    [switch]$ReturnRawRule
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach rule item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Rule |
      Where-Object -FilterScript {
        ($_.Name -like ${Name}) -and
        ($_ -is [VMware.Vim.ClusterAffinityRuleSpec] -or $_ -is [VMware.Vim.ClusterAntiAffinityRuleSpec])
      } |
      ForEach-Object -Process {
        if ($ReturnRawRule) {$_}
        else{
          New-Object DRSRule.VMToVMRule -Property @{
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

#.ExternalHelp DRSRule.Help.xml
Function Get-DrsVMToVMHostRule
{
  [CmdletBinding()]
  [OutputType([DRSRule.VMToVMHostRule],[VMware.Vim.ClusterVmHostRuleInfo])]
  param(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]${Name} = '*',
    [Parameter(Position = 1, ValueFromPipeline = $True)]
    [PSObject[]]${Cluster},
    [switch]$ReturnRawRule
  )

  Process {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## update the View data, in case it was stale
      $oThisCluster.ExtensionData.UpdateViewData("ConfigurationEx")
      ## foreach rule item, return something
      $oThisCluster.ExtensionData.ConfigurationEx.Rule |
      Where-Object -FilterScript {
        $_.Name -like ${Name} -and
        $_ -is [VMware.Vim.ClusterVmHostRuleInfo]
      } |
      ForEach-Object -Process {
        if ($ReturnRawRule) {$_}
        else {
          New-Object DRSRule.VMToVMHostRule -Property @{
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
Function New-DrsVMGroup
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMGroup])]
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
      if ($oExistingVmGroup -and !$Force)
      {
        Throw "DRS VM group named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingVmGroup -and $Force)
      {
        ## changed to use item returned from Get-DrsVMGroup, instead of "$_", which was the cluster object
        $oExistingVmGroup | Remove-DrsVMGroup
      }
      else
      {
        Write-Verbose "Good -- no DRS group of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      $VM = $VM | Foreach-Object {
        $oThisVmItem = $_
        if($oThisVmItem -is [System.String]){
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VM -Name $oThisVmItem -ErrorAction:Stop
          }
          catch {Throw "No VM of name '$oThisVmItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"}
        }
        else{
          $oThisVmItem
        }
      }
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create DRS VM group '${Name}'"))
      {
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
Function New-DrsVMHostGroup
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMHostGroup])]
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
      if ($oExistingVMHostGroup -and !$Force)
      {
        Throw "DRS VMHost group named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingVMHostGroup -and $Force)
      {
        $oExistingVMHostGroup | Remove-DrsVMHostGroup
      }
      else
      {
        Write-Verbose "Good -- no DRS group of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      $VMHost = $VMHost | Foreach-Object {
        $oThisVMHostItem = $_
        if($oThisVMHostItem -is [System.String]){
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VMHost -Name $oThisVMHostItem -ErrorAction:Stop
          }
          catch {Throw "No VMHost of name '$oThisVMHostItem' found in cluster '$($oThisCluster.Name)'. Valid VMHost name?"}
        }
        else{
          $oThisVMHostItem
        }
      }
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create DRS VMHost group '${Name}'"))
      {
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
Function New-DrsVMToVMHostRule
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMToVMHostRule])]
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

  Process
  {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if rule of this name already exists in this cluster
      $oExistingRule = Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name $Name
      if ($oExistingRule -and !$Force)
      {
        Throw "DRS rule named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingRule -and $Force)
      {
        $oExistingRule | Remove-DrsVMToVMHostRule
      }
      else
      {
        Write-Verbose "Good -- no DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      ## check if VMGroupName and AffineHostGroupName/AntiAffineHostGroupName (the one specified) are valid groups in this cluster
      if ($null -eq (Get-DrsVMGroup -Cluster $oThisCluster -Name $VMGroupName)) {Throw "No DrsVmGroup named '$VMGroupName' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVmGroup '$VMGroupName' found in cluster '$($oThisCluster.Name)'"}

      $strDrsVMHostGroupNameToCheck = ${AffineHostGroupName},${AntiAffineHostGroupName} | Where-Object {-not [String]::IsNullOrEmpty($_)}
      if(!$strDrsVMHostGroupNameToCheck)
      {
        Throw "No VMHostGroup specified for new rule on cluster $($oThisCluster.Name)"
      }
      if ($null -eq (Get-DrsVMHostGroup -Cluster $oThisCluster -Name $strDrsVMHostGroupNameToCheck)) {Throw "No DrsVMHostGroup named '$strDrsVMHostGroupNameToCheck' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVMHostGroup '$strDrsVMHostGroupNameToCheck' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create $(if ([String]::IsNullOrEmpty(${AffineHostGroupName})) {'AffineVMToVMHost'} else {'AntiAffineVMToVMHost'}) DRS rule '${Name}'"))
      {
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
Function New-DrsVMToVMRule
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMToVMRule])]
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

  Process
  {
    Get-ClusterObjFromClusterParam -Cluster $Cluster | ForEach-Object -Process {
      $oThisCluster = $_
      ## check if rule of this name already exists in this cluster
      $oExistingRule = Get-DrsVMtoVMRule -Cluster $oThisCluster -Name $Name
      if ($oExistingRule -and !$Force)
      {
        Throw "DRS rule named '$Name' already exists in cluster '$($oThisCluster.Name)'"
      }
      elseif($oExistingRule -and $Force)
      {
        $oExistingRule | Remove-DrsVMToVMRule
      }
      else
      {
        Write-Verbose "Good -- no DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"
      }

      $VM = $VM | Foreach-Object {
        $oThisVmItem = $_
        if($oThisVmItem -is [System.String]){
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VM -Name $oThisVmItem -ErrorAction:Stop
          }
          catch {Throw "No VM of name '$oThisVmItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"}
        }
        else{
          $oThisVmItem
        }
      }
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Create DRS VM $(if (${KeepTogether}) {'KeepTogether'} else {'KeepApart'}) rule '${Name}'"))
      {
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
Function Remove-DrsVMGroup
{
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
      ## check that VMGroup exists
      $target = @(Get-DrsVMGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup)
      if ($null -eq $target) {Throw "No DrsVmGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVmGroup '$Name' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS VM group '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | %{
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
Function Remove-DrsVMHostGroup
{
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
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS Host group '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | %{
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
Function Remove-DrsVMToVMHostRule
{
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

  Process{
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## verify that rule of this name exists in this cluster
      $target = @(Get-DrsVMtoVMHostRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule)
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS rule '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | %{
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
Function Remove-DrsVMToVMRule
{
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

  Process{
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## verify that rule of this name exists in this cluster
      $target = @(Get-DrsVMtoVMRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule)
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Remove DRS rule '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $target | %{
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
Function Set-DrsVMGroup
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMGroup])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},
    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},
    [parameter(ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a VM obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine])
    })]
    [PSObject[]]${VM},
    [Switch]${Append}
  )

  Process{
   Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      $VM = $VM | Foreach-Object {
        $oThisVmItem = $_
        if($_ -is [System.String]){
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VM -Name $oThisVmItem -ErrorAction:Stop
          }
          catch {Throw "No VM of name '$oThisVmItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"}
        }
        else{
          $oThisVmItem
        }
      }
      ## check that VMGroup exists
      $target = Get-DrsVMGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup
      if ($null -eq $target) {Throw "No DrsVmGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVmGroup '$Name' found in cluster '$($oThisCluster.Name)'"}
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS VM group '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
        $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit
        $groupSpec.Info = $target
        $arrNewMembersIds = ${VM} | ForEach-Object -Process {$_.Id}
        if(${Append}) {
          $groupSpec.Info.VM += $arrNewMembersIds
        }
        else {
          $groupSpec.Info.VM = $arrNewMembersIds
        }
        $spec.GroupSpec += $groupSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)

        Get-DrsVMGroup -Cluster ${Cluster} -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Set-DrsVMHostGroup
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMHostGroup])]
  param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [string]${Name},
    [Parameter(Mandatory = $True, Position = 1, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a Cluster obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster])
    })]
    [PSObject[]]${Cluster},
    [ValidateNotNullOrEmpty()][ValidateScript({
      ## make sure that all values are either a String or a VMHost obj
      _Test-TypeOrString -Object $_ -Type ([VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost])
    })]
    [PSObject[]]${VMHost},
    [Switch]${Append}
  )

  Process{
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      $VMHost = $VMHost | Foreach-Object {
        $oThisVMHostItem = $_
        if($_ -is [System.String]){
          try {
            ## limit scope to this cluster
            $oThisCluster | Get-VMHost -Name $oThisVMHostItem -ErrorAction:Stop
          }
          catch {Throw "No VMHost of name '$oThisVMHostItem' found in cluster '$($oThisCluster.Name)'. Valid VMHost name?"}
        }
        else{
          $oThisVMHostItem
        }
      }
      ## check that VMHostGroup exists
      $target = Get-DrsVMHostGroup -Cluster $oThisCluster -Name $Name -ReturnRawGroup
      if ($null -eq $target) {Throw "No DrsVMHostGroup named '$Name' in cluster '$($oThisCluster.Name)'. Valid group name?"}
      else {Write-Verbose "DrsVMHostGroup '$Name' found in cluster '$($oThisCluster.Name)'"}
      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS Host group '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $groupSpec = New-Object VMware.Vim.ClusterGroupSpec
        $groupSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit
        $groupSpec.Info = $target
        $arrNewMembersIds = ${VMHost} | ForEach-Object -Process {$_.Id}
        if(${Append}) {
          $groupSpec.Info.Host += $arrNewMembersIds
        }
        else {
          $groupSpec.Info.Host = $arrNewMembersIds
        }
        $spec.GroupSpec += $groupSpec

        $oThisCluster.ExtensionData.ReconfigureComputeResource($spec,$True)

        Get-DrsVMHostGroup -Cluster ${Cluster} -Name ${Name}
      }
    }
  }
}

#.ExternalHelp DRSRule.Help.xml
Function Set-DrsVMToVMHostRule
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMToVMHostRule])]
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

  Process{
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

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS rule '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
        $ruleSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit
        $ruleSpec.Info = $target
        if($PSBoundParameters.ContainsKey("Enabled"))
        {
          $ruleSpec.Info.Enabled = ${Enabled}
        }
        if($null -ne ${VMGroup})
        {
          $ruleSpec.Info.VmGroupName = ${VMGroup}
        }
        if($PSBoundParameters.ContainsKey("Mandatory"))
        {
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
          if ($null -ne $target.AffineHostGroupName)
          {
            $ruleSpec.Info.AffineHostGroupName = ${VMHostGroup}
            $ruleSpec.Info.AntiAffineHostGroupName = $null
          }
          ## else, set the antiaffine group to the new value
          else
          {
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
Function Set-DrsVMToVMRule
{
  [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = [System.Management.Automation.Confirmimpact]::Medium)]
  [OutputType([DRSRule.VMToVMRule])]
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

  Process{
    Get-ClusterObjFromClusterParam -Cluster ${Cluster} | ForEach-Object -Process {
      $oThisCluster = $_
      ## verify that rule of this name exists in this cluster
      $target = Get-DrsVMtoVMRule -Cluster $oThisCluster -Name ${Name} -ReturnRawRule
      if ($null -eq $target) {Throw "No DRS rule named '$Name' exists in cluster '$($oThisCluster.Name)'"}
      else {Write-Verbose "Good -- DRS rule of name '$Name' found in cluster '$($oThisCluster.Name)'"}

      ## verify that VM exists
      if($PSBoundParameters.ContainsKey("VM")){
        $VM = $VM | Foreach-Object {
          $oThisVMItem = $_
          if($_ -is [System.String]){
            try {
              ## limit scope to this cluster
              $oThisCluster | Get-VM -Name $oThisVMItem -ErrorAction:Stop
            }
            catch {Throw "No VM of name '$oThisVMItem' found in cluster '$($oThisCluster.Name)'. Valid VM name?"}
          }
          else{
            $oThisVMItem
          }
        }
      }

      if($psCmdlet.ShouldProcess("$($oThisCluster.Name)","Set DRS rule '${Name}'"))
      {
        $spec = New-Object VMware.Vim.ClusterConfigSpecEx
        $ruleSpec = New-Object VMware.Vim.ClusterRuleSpec
        $ruleSpec.Operation = [VMware.Vim.ArrayUpdateOperation]::edit

        ## Check if -KeepTogether param passed
        $ruleSpec.Info = $(
          if($PSBoundParameters.ContainsKey('KeepTogether'))
          {
            if(${KeepTogether})
            {
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
            else
            {
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
          else
          {
            $target
          }
        )

        ## Enabled switch
        if($PSBoundParameters.ContainsKey("Enabled"))
        {
          $ruleSpec.Info.Enabled = ${Enabled}
        }
        if($PSBoundParameters.ContainsKey("Mandatory")) {
          $ruleSpec.Info.Mandatory = ${Mandatory}
        }
        ## VM passed
        if($PSBoundParameters.ContainsKey("VM"))
        {
          if(${Append})
          {
            $ruleSpec.Info.VM = $ruleSpec.Info.VM + $($VM | Foreach-Object {$_.Id})
          }
          else
          {
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
Function Export-DrsRule
{
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

  Process
  {
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

#.ExternalHelp DRSRule.Help.xml
Function Import-DrsRule
{
  [CmdletBinding(SupportsShouldProcess=$true)]
  [OutputType([DRSRule.VMGroup],[DRSRule.VMHostGroup],[DRSRule.VMToVMRule],[DRSRule.VMToVMHostRule])]
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
if(Test-Path -Path $ManifestPathAndFile)
{
  $Manifest = (Get-Content -raw $ManifestPathAndFile) | Invoke-Expression
  foreach( $ScriptToProcess in $Manifest.ScriptsToProcess)
  {
    $ModuleToRemove = (Get-Item (Join-Path -Path $PSScriptRoot -ChildPath $ScriptToProcess)).BaseName
    if(Get-Module $ModuleToRemove)
    {
      Remove-Module $ModuleToRemove
    }
  }
}
