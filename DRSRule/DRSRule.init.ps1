## make the PowerShell classes for objects in this module
class DRSRule_VMGroup {
    ## Name of the Group
    [string]$Name
    ## HA/DRS Cluster in which group resides
    [string]$Cluster
    ## Name(s) of VMs in group
    [string[]]$VM
    ## MoRef(s) of VM(s) in group
    [VMware.Vim.ManagedObjectReference[]]$VMId
    ## Is the group user-created?
    [bool]$UserCreated
    ## What type of group is this?
    [string]$Type
} ## end class

class DRSRule_VMHostGroup {
    ## Name of the Group
    [string]$Name
    ## HA/DRS Cluster in which group resides
    [string]$Cluster
    ## Name(s) of VMHosts in group
    [string[]]$VMHost
    ## MoRef(s) of VMHost(s) in group
    [VMware.Vim.ManagedObjectReference[]]$VMHostId
    ## Is the group user-created?
    [bool]$UserCreated
    ## What type of group is this?
    [string]$Type
} ## end class

class DRSRule_VMToVMRule {
    ## Name of the Rule
    [string]$Name
    ## HA/DRS Cluster in which rule resides
    [string]$Cluster
    ## ID of the Cluster in which rule resides
    [string]$ClusterId
    ## Rule enabled?
    [bool]$Enabled
    ## Rule mandatory ("must run" instead of "should run"?)
    [bool]$Mandatory
    ## Keep VMs together?
    [bool]$KeepTogether
    ## Name(s) of VM(s) in rule
    [string[]]$VM
    ## MoRef(s) of VM(s) in rule
    [VMware.Vim.ManagedObjectReference[]]$VMId
    ## Is the rule user-created?
    [bool]$UserCreated
    ## What type of rule is this?
    [string]$Type
} ## end class

class DRSRule_VMToVMHostRule {
    ## Name of the Rule
    [string]$Name
    ## HA/DRS Cluster in which rule resides
    [string]$Cluster
    ## ID of the Cluster in which rule resides
    [string]$ClusterId
    ## Rule enabled?
    [bool]$Enabled
    ## Rule mandatory ("must run" instead of "should run"?)
    [bool]$Mandatory
    ## Name of the VMGroup involved in the rule
    [string]$VMGroupName
    ## Name of the VMHostGroup to which VMGroup is affine
    [string]$AffineHostGroupName
    ## Name of the VMHostGroup to which VMGroup is antiaffine
    [string]$AntiAffineHostGroupName
    ## Is the rule user-created?
    [bool]$UserCreated
    ## What type of rule is this?
    [string]$Type
} ## end class


# ## VM or template name completer
# $sbGetVmOrTemplateNameCompleter = {
#     param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
#     Get-View -ViewType VirtualMachine -Property Name, Runtime.Powerstate -Filter @{Name = "^${wordToComplete}"; "Config.Template" = ($commandName -ne "Get-VM").ToString()} | Sort-Object -Property Name | Foreach-Object {
#         New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList (
#             $_.Name,    # CompletionText
#             $_.Name,    # ListItemText
#             [System.Management.Automation.CompletionResultType]::ParameterValue,    # ResultType
#             ("{0} ({1})" -f $_.Name, $_.Runtime.PowerState)    # ToolTip
#         )
#     } ## end foreach-object
# } ## end scriptblock

# Register-ArgumentCompleter -CommandName Get-VM, Get-Template -ParameterName Name -ScriptBlock $sbGetVmOrTemplateNameCompleter


# multiple DRSRule object item name completer
$sbGetDRSRuleItemNameCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    ## determine the cmdlet(s) to use to get Name(s) of relevant objects, based on the types of objects that the given $commandName expects; like, Export-DRSRule can take the name of any DRSRule object -- rules, groups
    $arrCmdletsToUseToGetDesiredObjects = Switch ($commandName) {
        {$_ -in (Write-Output Get-DrsVMGroup, Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, Get-DrsVMToVMRule)} {$_}
        "New-DrsVMToVMHostRule" {
            Switch ($parameterName) {
                "VMGroupName" {"Get-DrsVMGroup"}
                {$_ -in "AffineHostGroupName", "AntiAffineHostGroupName"} {"Get-DrsVMHostGroup"}
            } ## end inner switch
        } ## end case
        {$_ -in (Write-Output Remove-DrsVMGroup, Set-DrsVMGroup)} {"Get-DrsVMGroup"}
        {$_ -in (Write-Output Remove-DrsVMHostGroup, Set-DrsVMHostGroup)} {"Get-DrsVMHostGroup"}
        "Remove-DrsVMToVMHostRule" {"Get-DrsVMToVMHostRule"}
        {$_ -in (Write-Output Remove-DrsVMToVMRule, Set-DrsVMToVMRule)} {"Get-DrsVMToVMRule"}
        "Set-DrsVMToVMHostRule" {
            Switch ($parameterName) {
                "Name" {"Get-DrsVMToVMHostRule"}
                "VMGroup" {"Get-DrsVMGroup"}
                "VMHostGroup" {"Get-DrsVMHostGroup"}
            } ## end inner switch
        } ## end case
        {$_ -in (Write-Output Export-DrsRule)} {"Get-DrsVMGroup", "Get-DrsVMHostGroup", "Get-DrsVMToVMHostRule", "Get-DrsVMToVMRule"}
    } ## end switch

    ## make the regex pattern to use for Name filtering for given View object (convert from globbing wildcard to regex pattern, to support globbing wildcard as input)
    $strNameWildcard = if ($wordToComplete -notmatch "\*$") {"${wordToComplete}*"} else {$wordToComplete}
    ## get the possible matches, create a new CompletionResult object for each
    $arrCmdletsToUseToGetDesiredObjects | Foreach-Object {& $_ -Name $strNameWildcard | Sort-Object -Property Name -Unique} | Foreach-Object {
        ## make the Completion and ListItem text values; happen to be the same for now, but could be <anything of interest/value>
        $strCompletionText = $strListItemText = if ($_.Name -match "\s") {'"{0}"' -f $_.Name} else {$_.Name}
        New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList (
            $strCompletionText,    # CompletionText
            $strListItemText,    # ListItemText
            [System.Management.Automation.CompletionResultType]::ParameterValue,    # ResultType
            ("{0} (cluster '{1}')" -f $_.Name, $_.Cluster)    # ToolTip
        )
    } ## end foreach-object
} ## end scriptblock

## reg an arg completer for the Name param for all of these commands
Register-ArgumentCompleter -ParameterName Name -CommandName Export-DrsRule, Get-DrsVMGroup, Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, Get-DrsVMToVMRule, Remove-DrsVMGroup, Remove-DrsVMHostGroup, Remove-DrsVMToVMHostRule, Remove-DrsVMToVMRule, Set-DrsVMGroup, Set-DrsVMHostGroup, Set-DrsVMToVMHostRule, Set-DrsVMToVMRule -ScriptBlock $sbGetDRSRuleItemNameCompleter
## reg an arg completer for the given params for this command
Write-Output VMGroupName, AffineHostGroupName, AntiAffineHostGroupName | Foreach-Object {Register-ArgumentCompleter -ParameterName $_ -CommandName New-DrsVMToVMHostRule -ScriptBlock $sbGetDRSRuleItemNameCompleter}
## reg an arg completer for the given params for this command
Write-Output Name, VMGroup, VMHostGroup | Foreach-Object {Register-ArgumentCompleter -ParameterName $_ -CommandName Set-DrsVMToVMHostRule -ScriptBlock $sbGetDRSRuleItemNameCompleter}


# ## multiple "core" item name completer, like cluster, hostsystem, virtualmachine
$sbGetCoreVSphereItemNameCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    ## determine the VMware View object type to use to get Name(s) of relevant objects, based on the types of objects that the given $commandName expects; like, the DRS cmdlets take the -Cluster parameter
    $strViewTypeToUseToGetDesiredObjects = Switch ($commandName) {
        {$_ -in (Write-Output Export-DrsRule, Get-DrsVMGroup, Get-DrsVMToVMRule, Import-DrsRule, New-DrsVMGroup,New-DrsVMToVMHostRule, New-DrsVMToVMRule, Remove-DrsVMGroup, Remove-DrsVMHostGroup, Remove-DrsVMToVMHostRule, Remove-DrsVMToVMRule, Set-DrsVMGroup, Set-DrsVMToVMHostRule, Set-DrsVMToVMRule)} {"ClusterComputeResource"}
        {$_ -in (Write-Output Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, New-DrsVMHostGroup, Set-DrsVMHostGroup)} {
            Switch ($parameterName) {
                "Cluster" {"ClusterComputeResource"}
                {$_ -in (Write-Output AddVMHost, VMHost)} {"HostSystem"}
            } ## end inner switch
        } ## end case
    } ## end switch

    ## make the regex pattern to use for Name filtering for given View object (convert from globbing wildcard to regex pattern, to support globbing wildcard as input)
    $strNameRegex = if ($wordToComplete -match "\*") {$wordToComplete.Replace("*", ".*")} else {$wordToComplete}
    ## get the possible matches, create a new CompletionResult object for each
    Get-View -ViewType $strViewTypeToUseToGetDesiredObjects -Property Name -Filter @{Name = "^${strNameRegex}"} | Sort-Object -Property Name -Unique | Foreach-Object {
        ## make the Completion and ListItem text values; happen to be the same for now, but could be <anything of interest/value>
        $strCompletionText = $strListItemText = if ($_.Name -match "\s") {'"{0}"' -f $_.Name} else {$_.Name}
        New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList (
            $strCompletionText,    # CompletionText
            $strListItemText,    # ListItemText
            [System.Management.Automation.CompletionResultType]::ParameterValue,    # ResultType
            ("{0} ('{1}')" -f $_.Name, $_.MoRef)    # ToolTip
        )
    } ## end foreach-object
} ## end scriptblock

## reg an arg completer for the Cluster param for all of these commands
Register-ArgumentCompleter -ParameterName Cluster -CommandName Export-DrsRule, Get-DrsVMGroup, Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, Get-DrsVMToVMRule, Import-DrsRule, New-DrsVMGroup, New-DrsVMHostGroup, New-DrsVMToVMHostRule, New-DrsVMToVMRule, Remove-DrsVMGroup, Remove-DrsVMHostGroup, Remove-DrsVMToVMHostRule, Remove-DrsVMToVMRule, Set-DrsVMGroup, Set-DrsVMHostGroup, Set-DrsVMToVMHostRule, Set-DrsVMToVMRule -ScriptBlock $sbGetCoreVSphereItemNameCompleter
## reg an arg completer for the given param for these commands
Register-ArgumentCompleter -ParameterName VMHost -CommandName Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, New-DrsVMHostGroup, Set-DrsVMHostGroup -ScriptBlock $sbGetCoreVSphereItemNameCompleter
## reg an arg completer for the given param for this command
Register-ArgumentCompleter -ParameterName AddVMHost -CommandName Set-DrsVMHostGroup -ScriptBlock $sbGetCoreVSphereItemNameCompleter

