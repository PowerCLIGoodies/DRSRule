## make Argument Completers for cmdlets in the module
## get the params for cmdlets in the module, so as to have info by which to create arg completers
# (Get-command -Module DRSRule).Parameters.Keys | Select-Object -Unique | Sort-Object | Select-Object -Property @{n="ParameterName"; e={$_}}, @{n="Cmdlet"; e={Get-Command -Module DRSRule -ParameterName $_}}
# ParameterName : AddVM
# Cmdlet        : Set-DrsVMGroup

## not doing this one yet -- would ideally only list the VM names that are a part of the given VMGroup (instead of just all VMs in vCenter)
# ParameterName : RemoveVM
# Cmdlet        : Set-DrsVMGroup

# ParameterName : VM
# Cmdlet        : {Get-DrsVMGroup, Get-DrsVMToVMHostRule, Get-DrsVMToVMRule, New-DrsVMGroup, New-DrsVMToVMRule, Set-DrsVMGroup, Set-DrsVMToVMRule}

# ParameterName : AddVMHost
# Cmdlet        : Set-DrsVMHostGroup

## not doing this one yet -- would ideally only list the VMHost names that are a part of the given VMHostGroup (instead of just all VMHosts in vCenter)
# ParameterName : RemoveVMHost
# Cmdlet        : Set-DrsVMHostGroup

# ParameterName : VMHost
# Cmdlet        : {Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, New-DrsVMHostGroup, Set-DrsVMHostGroup}

# ParameterName : Cluster
# Cmdlet        : {Export-DrsRule, Get-DrsVMGroup, Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, Get-DrsVMToVMRule, Import-DrsRule, New-DrsVMGroup, New-DrsVMHostGroup, New-DrsVMToVMHostRule, New-DrsVMToVMRule, Remove-DrsVMGroup, Remove-DrsVMHostGroup, Remove-DrsVMToVMHostRule, Remove-DrsVMToVMRule, Set-DrsVMGroup, Set-DrsVMHostGroup, Set-DrsVMToVMHostRule, Set-DrsVMToVMRule}

# ParameterName : AffineHostGroupName
# Cmdlet        : New-DrsVMToVMHostRule

# ParameterName : AntiAffineHostGroupName
# Cmdlet        : New-DrsVMToVMHostRule

# ParameterName : Name
# Cmdlet        : {Export-DrsRule, Get-DrsVMGroup, Get-DrsVMHostGroup, Get-DrsVMToVMHostRule, Get-DrsVMToVMRule, Remove-DrsVMGroup, Remove-DrsVMHostGroup, Remove-DrsVMToVMHostRule, Remove-DrsVMToVMRule, Set-DrsVMGroup, Set-DrsVMHostGroup, Set-DrsVMToVMHostRule, Set-DrsVMToVMRule}
## not doing Import-DrsRule (that should get rule names from the JSON itself, not from the environment, right?)

# ParameterName : VMGroup
# Cmdlet        : Set-DrsVMToVMHostRule

# ParameterName : VMGroupName
# Cmdlet        : New-DrsVMToVMHostRule

# ParameterName : VMHostGroup
# Cmdlet        : Set-DrsVMToVMHostRule
