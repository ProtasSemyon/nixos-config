{ ... }:

{
  # AMD CPU + integrated/discrete Radeon graphics. Imported by the hosts that
  # have AMD silicon; everything in here is vendor-specific but not
  # machine-specific (per-machine quirks live in hosts/<host>/default.nix).

  # Load amdgpu in stage 1 instead of waiting for stage 2: the panel comes up at
  # its native mode straight away and Plymouth stops flipping modes mid-boot.
  hardware.amdgpu.initrd.enable = true;

  services.xserver.videoDrivers = [ "amdgpu" ];

  # amd-pstate in active (EPP) mode. TLP steers the power/performance
  # trade-off through EPP rather than the scaling governor; see power.nix.
  boot.kernelParams = [ "amd_pstate=active" ];
}
