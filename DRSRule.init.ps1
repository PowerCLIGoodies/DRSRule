## the version of PowerCLI at which the path to "VMware.Vim.dll" change from "${env:\ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\." (two folders up from the core module's directory) to the VMware.VimAutomation.Core module directory
## build 4624819 is PowerCLI 6.5rel1 -- 6.5.0, build 4624819; this (6.5rel1) is module version 6.5.0.2604913
$verPowerCLIWhereDllMoved = [System.Version]"6.5.0.2604913"

$oModuleInfo = Get-Module -ListAvailable -Name VMware.VimAutomation.Core
## the directory in which the VMware.Vim.dll file resides, based on module version
$strVMwareVimDllDirectory = if ($oModuleInfo.Version -ge $verPowerCLIWhereDllMoved) {$oModuleInfo.ModuleBase} else {(Get-Item (Get-Module VMware.VimAutomation.Core).ModuleBase).Parent.Parent.FullName}
## the full filespec of the DLL
$pcliDll = Join-Path -Path $strVMwareVimDllDirectory -ChildPath "VMware.Vim.dll"

Add-Type -ReferencedAssemblies $pcliDll -TypeDefinition @"
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
