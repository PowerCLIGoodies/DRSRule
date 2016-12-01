if((Get-PowerCLIVersion).Build -ge 4624819){
    $pcliDll = "${env:\ProgramFiles(x86)}\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Core\VMware.Vim.dll"
}
else{
    $pcliDll = "${env:\ProgramFiles(x86)}\VMware\Infrastructure\vSphere PowerCLI\VMware.Vim.dll"
}

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
