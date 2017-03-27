## DRSRule PowerShell module

### Changelog

### v1.next
- \[enhancement] added support for enhancement suggested in [Issue #7](https://github.com/PowerCLIGoodies/DRSRule/issues/7): get a DRS `VMGroup` by the related VM; while at it, added support for getting a DRS `VMHostGroup` by the related VMHost, DRS `VMToVMRule` by VM, and DRS `VMToVMHostRule` by VM or VMHost
- \[improvment] added [Pester](https://github.com/pester/Pester) tests for `Get-Drs*` cmdlets

### v1.0.1

30 Jun 2015

- \[bugfix] fixed rare problem with creating new `DRSRule.VMHostGroup` for VMHost group item where `Host` property of corresponding `VMware.Vim.ClusterHostGroup` object is empty and user is using PowerShell v5 (credit [gpduck](https://github.com/gpduck)). This was in `Get-DrsVMHostGroup`. Updated similar situation for functions `Get-DrsVMGroup` and `Get-DrsVMToVMRule`.

### v1.0.0

Initial release, 21 Jan 2015.
