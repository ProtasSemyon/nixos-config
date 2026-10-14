{
  config,
  lib,
  inputs,
  self,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    ../../modules/nixos/amd.nix
  ];

  networking.hostName = "fx505dd";
  time.timeZone = "Europe/Minsk";

  # ---------------------------------------------------------------------------
  # Storage
  # ---------------------------------------------------------------------------
  # Root lives in the unallocated half of the 1 TB SSD; the Windows data
  # partition takes the other half and is left alone.
  fileSystems."/".options = [
    "noatime"
    "ssd"
    "space_cache=v2"
    "discard=async"
    "compress=zstd"
  ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Size to taste once the installed RAM is known — this chassis shipped with
  # 8 and 16 GiB configurations.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  nix.settings.max-jobs = 4;

  # ---------------------------------------------------------------------------
  # Dual boot with Windows
  # ---------------------------------------------------------------------------
  # NixOS has its own ESP on its own disk (see ./hardware-configuration.nix),
  # so efiSysMountPoint stays at the default /boot and the Windows disk is
  # never written to.

  # Picks up the Windows bootloader on the other disk and adds an entry for it.
  # os-prober runs at nixos-rebuild time, not at boot, so if the entry is
  # missing just rebuild again.
  boot.loader.grub.useOSProber = true;

  # A kernel + initrd per generation is roughly 100 MiB, so bound what the
  # 2 GiB ESP has to hold. Older generations stay in the store and in
  # `nixos-rebuild --rollback`; they just drop off the boot menu.
  boot.loader.grub.configurationLimit = 10;

  # Windows keeps the RTC in local time and rewrites it on every boot, which
  # otherwise shifts the clock in NixOS by the UTC offset each time the machine
  # is handed over. The alternative is to teach Windows to use UTC
  # (RealTimeIsUniversal in the registry); do one or the other, not both.
  time.hardwareClockInLocalTime = true;

  # So the Windows partition can be mounted from NixOS. Note that it stays
  # locked read-only unless Fast Startup and hibernation are turned off in
  # Windows — it leaves the NTFS volume in a dirty state otherwise.
  boot.supportedFilesystems.ntfs = true;

  # ---------------------------------------------------------------------------
  # Panel
  # ---------------------------------------------------------------------------
  # 15.6" 1080p, driven by the Vega iGPU (this is a muxless Optimus machine).
  # The 120 Hz variant of this model should set refreshRate.ac = 120.
  host.display.internal = {
    output = "eDP-1";
    mode = "1920x1080";
    scale = "1";
    refreshRate = {
      ac = 60;
      battery = 60;
    };
    # ASUS firmware names the mains adapter ADP0 rather than the ACAD that the
    # Lenovo uses. Confirm with `ls /sys/class/power_supply`; if it is wrong the
    # script just assumes AC and always picks the higher rate.
    acDevice = "ADP0";
  };

  # ---------------------------------------------------------------------------
  # Wi-Fi — Realtek RTL8821CE
  # ---------------------------------------------------------------------------
  # Handled by the in-tree rtw88_8821ce driver. The out-of-tree tomaspinho
  # driver that the old guides point at is gone from nixpkgs ("removed due to
  # lack of maintenance"), and is not needed: the chip has been in rtw88 since
  # 5.9.
  #
  # What is still needed are two power-saving workarounds. The 8821CE only
  # leaves ASPM L1 briefly when an IRQ is raised, and IRQs are masked during
  # NAPI poll, so the link stays in L1 and RX DMA crawls — that is the classic
  # "connected but no throughput" symptom. Deep LPS additionally deadlocks the
  # firmware on this chip, which shows up as hard freezes. Both parameter names
  # were checked against the rtw88 modules in kernel 6.18.
  #
  # disable_aspm costs some idle power. If a future kernel carries a DMI quirk
  # for this laptop, drop these again.
  boot.extraModprobeConfig = ''
    options rtw88_pci disable_aspm=1
    options rtw88_core disable_lps_deep=y
  '';

  # NetworkManager's own powersave puts the chip back into the state the two
  # module parameters above exist to avoid.
  networking.networkmanager.wifi.powersave = false;

  # ...and so does TLP's, which modules/nixos/power.nix turns on for well-behaved
  # cards.
  services.tlp.settings.WIFI_PWR_ON_BAT = lib.mkForce "off";

  # ---------------------------------------------------------------------------
  # Graphics — Vega 8 iGPU + GeForce GTX 1050 (PRIME offload)
  # ---------------------------------------------------------------------------
  # The internal panel hangs off the iGPU; the dGPU is used on demand via
  # `nvidia-offload <cmd>` (the wrapper comes from nixos-hardware's prime
  # module). modules/nixos/amd.nix already puts "amdgpu" in videoDrivers; this
  # appends the NVIDIA one.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Pascal predates the open kernel modules, and 580 is the last branch that
    # supports it.
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    modesetting.enable = true;

    # VERIFY ON THE MACHINE before the first switch: `lspci -D | grep -E 'VGA|3D'`
    # and convert, e.g. 0000:01:00.0 -> "PCI:1:0:0". These are the values this
    # model usually reports, but a wrong ID breaks the session.
    prime = {
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Adds a "battery-saver" boot entry with the dGPU fully disabled.
  hardware.nvidia.primeBatterySaverSpecialisation = true;

  # Deliberately no `programs.gamemode.settings.gpu` here: the card index is
  # ambiguous on a hybrid machine, and pinning the DPM level of the wrong one
  # is worse than leaving it alone. Set it once `ls /sys/class/drm` is known.

  # ---------------------------------------------------------------------------
  # ASUS platform
  # ---------------------------------------------------------------------------
  # Keyboard backlight, fan curves and power profiles via asusd. It also owns
  # the ACPI platform profile, so TLP's PLATFORM_PROFILE_* is intentionally not
  # set on this host — the two would fight.
  services.asusd.enable = true;

  # Charge limit via the kernel's charge_control_end_threshold (nixos-hardware's
  # asus-battery module). asusctl can also set this; keep it in one place.
  hardware.asus.battery.chargeUpto = 80;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs self username; };
    users.${username}.imports = [
      ../../home
      ./home.nix
    ];
  };

  system.stateVersion = "26.05";
}
