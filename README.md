# DRSRule PowerShell module ReadMe#
The DRSRule module allows you to work with all types of vSphere DRS rules.
The module provides support for VM and VMHost groups.  And, it works with affinity/anti-affinity VM rules and VM to VMHost rules.

### Brief info on module ###
The module came from the need for DRS rule/group info gathering, exporting, and recreating.  Initially there were some code blocks for exporting rule info and for importing again those rules, but things evolved into a module.

A couple of examples:
- Export rule/group info:  `Export-DrsRule -Path c:\someFolder\myDrsRuleAndGroupInfo.json`
- Import rule/group info:  `Import-DrsRule -Path c:\someFolder\myDrsRuleAndGroupInfo.json`

### How to set up the DRSRule module for use ###
* Download and extract the module .zip file
* `Unblock-File` on the extracted contents
* `Import-Module <path\To\ModuleFolder>`
* Use `Get-Help` as per usual for cmdlet help and examples

### Cmdlets in this module ###
- Export/Import:
	- Export-DrsRule
	- Import-DrsRule
- Get:
	- Get-DrsVMGroup
	- Get-DrsVMHostGroup
	- Get-DrsVMToVMHostRule
	- Get-DrsVMToVMRule
- New:
	- New-DrsVMGroup
	- New-DrsVMHostGroup
	- New-DrsVMToVMHostRule
	- New-DrsVMToVMRule
- Remove:
	- Remove-DrsVMGroup
	- Remove-DrsVMHostGroup
	- Remove-DrsVMToVMHostRule
	- Remove-DrsVMToVMRule
- Set:
	- Set-DrsVMGroup
	- Set-DrsVMHostGroup
	- Set-DrsVMToVMHostRule
	- Set-DrsVMToVMRule
