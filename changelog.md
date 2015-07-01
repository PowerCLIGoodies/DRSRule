## DRSRule PowerShell module ##

### Changelog ###

### v1.0.1 ###

30 Jun 2015

- \[bugfix] fixed rare problem with creating new `DRSRule.VMHostGroup` for VMHost group item where `Host` property of corresponding `VMware.Vim.ClusterHostGroup` object is empty and user is using PowerShell v5 (credit [gpduck](https://github.com/gpduck)). This was in `Get-DrsVMHostGroup`. Updated similar situation for functions `Get-DrsVMGroup` and `Get-DrsVMToVMRule`.

### v1.0.0 ###

Initial release, 21 Jan 2015.
