## the version of PowerCLI at which the path to "VMware.Vim.dll" changed from "${env:\ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\." (two folders up from the core module's directory) to the VMware.VimAutomation.Core module directory
## build 4624819 is PowerCLI 6.5R1 (6.5.0, build 4624819); this (6.5rel1) is module version 6.5.0.2604913
$verPowerCLIWhereDllMovedToModuleDir = [System.Version]"6.5.0.2604913"
## the version of PowerShell at which the path to "VMware.Vim.dll" changed from the VMware.VimAutomation.Core module directory to the two subfolders 'net45' and 'netcoreapp2.0'; the .dll appropriate for the PowerShell version depends on if PowerShell is Windows PowerShell or PowerShell Core (net45 for Windows PowerShell, netcoreapp2.0 for PowerShell Core)
$verPowerCLIWhereDllMovedToDotNetSubdir = [System.Version]"10.0"
## the module in which "VMware.Vim.dll" now resides (this module was introduced to the overall VMware.PowerCLI module "family" at some point -- a point that we have not yet pin-"pointed")
$strVMwareModuleToWhichVimDllMoved = "VMware.Vim"

## do things to eventually determine the path to the VMware PowerCLI assembly "VMware.Vim.dll"; partially modeled after goodness in v10 of VMware.VimAutomation.Core.psm1 from VMware -- thanks, VMware!
## the supposed path in which "VMware.Vim.dll" resides
$strVMwareVimDllDirectory = `
## if this machine has a version of VMware.PowerCLI that has the VMware.Vim module, that is where the VMware.Vim.dll file resides
if (Get-Module -ListAvailable -Name VMware.Vim) {
  $oVMwareVimModuleInfo = if ($oTmp_currentlyLoadedVimModuleVersion = Get-Module -Name VMware.Vim -ErrorAction:SilentlyContinue) {$oTmp_currentlyLoadedVimModuleVersion} else {Get-Module -ListAvailable -Name VMware.Vim | Sort-Object -Property Version | Select-Object -Last 1}
  Join-Path -Path $oVMwareVimModuleInfo.ModuleBase -ChildPath $(if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne "Desktop")) {"netcoreapp2.0"} else {"net45"})
} ## end if
## else, look in the other, "traditional" spots for VMware.Vim.dll
else {
  ## get the module info for VMware.VimAutomation.Core module for either the currently loaded version (if any), or the latest version available in the PSModulePath otherwise
  $oModuleInfo = if ($oTmp_currentlyLoadedModuleVersion = Get-Module -Name VMware.VimAutomation.Core -ErrorAction:SilentlyContinue) {$oTmp_currentlyLoadedModuleVersion} else {Get-Module -ListAvailable -Name VMware.VimAutomation.Core | Sort-Object -Property Version | Select-Object -Last 1}
  ## the directory in which the VMware.Vim.dll file resides, based on module version
  if ($oModuleInfo.Version -ge $verPowerCLIWhereDllMovedToModuleDir) {
    ## if PowerCLI v10 or greater, get the appropriate, PowerShell-Edition-specific subdirectory from which to use the given .dll
    if ($oModuleInfo.Version -gt $verPowerCLIWhereDllMovedToDotNetSubdir) {
      $strDotNetSubdirNameToUse = if (($PSVersionTable.Keys -contains "PSEdition") -and ($PSVersionTable.PSEdition -ne "Desktop")) {"netcoreapp2.0"} else {"net45"}
      Join-Path -Path $oModuleInfo.ModuleBase -ChildPath $strDotNetSubdirNameToUse
    } ## end if
    ## else, the .dll is in the ModuleBase directory
    else {$oModuleInfo.ModuleBase}
  } ## end if
  ## else, the .dll is in the old location
  else {(Get-Item (Get-Module VMware.VimAutomation.Core).ModuleBase).Parent.Parent.FullName}
} ## end else
## the full filespec of the DLL
$strVMwareVimDllFilespec = Join-Path -Path $strVMwareVimDllDirectory -ChildPath "VMware.Vim.dll"

if (Test-Path -Path $strVMwareVimDllFilespec) {Write-Verbose "Hurray, we can reference 'VMware.Vim.dll'!"} else {Write-Warning "Uh-oh -- seemingly failed to locate 'VMware.Vim.dll' -- may have issue loading module (further work shall be done to make this process more robust)"}

Add-Type -ReferencedAssemblies $strVMwareVimDllFilespec -TypeDefinition @"
  using VMware.Vim;

  namespace DRSRule {
    public class VMGroup {
      public string Name;
      public string Cluster;
      public string[] VM;
      public ManagedObjectReference[] VMId;
      public bool UserCreated;
      public string Type;
      // not populated/used
      //public string Id;

      // Implicit constructor
      public VMGroup () {}
    }

    public class VMHostGroup {
      public string Name;
      public string Cluster;
      public string[] VMHost;
      public ManagedObjectReference[] VMHostId;
      public bool UserCreated;
      public string Type;
      //public string Id;

      // Implicit constructor
      public VMHostGroup () {}
    }

    public class VMToVMRule {
      public string Name;
      public string Cluster;
      public string ClusterId;
      public bool Enabled;
      public bool Mandatory;
      public bool KeepTogether;
      public string[] VM;
      public ManagedObjectReference[] VMId;
      public bool UserCreated;
      public string Type;

      // Implicit constructor
      public VMToVMRule () {}
    }

    public class VMToVMHostRule {
      public string Name;
      public string Cluster;
      public string ClusterId;
      public bool Enabled;
      public bool Mandatory;
      // KeepTogether is not a property of this type, but is deduced from which of the AffineHostGroupName/AntiAffineHostGroupName properties is populated
      //public bool KeepTogether;
      public string VMGroupName;
      public string AffineHostGroupName;
      public string AntiAffineHostGroupName;
      public bool UserCreated;
      public string Type;

      // Implicit constructor
      public VMToVMHostRule () {}
    }
  }
"@
