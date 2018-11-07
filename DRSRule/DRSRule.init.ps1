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
