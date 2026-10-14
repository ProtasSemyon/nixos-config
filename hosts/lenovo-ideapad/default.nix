{
  inputs,
  self,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./edid
    ../../modules/nixos
    ../../modules/nixos/amd.nix
  ];

  networking.hostName = "saymoon";
  time.timeZone = "Europe/Minsk";

  # ---------------------------------------------------------------------------
  # Storage
  # ---------------------------------------------------------------------------
  # Make the btrfs root mount options explicit (and thus reproducible) instead
  # of relying on whatever the running system happened to be mounted with.
  # noatime reduces write amplification; discard=async keeps the SSD trimmed;
  # compress=zstd transparently compresses new writes to save disk (the swapfile
  # is created nocow by NixOS, so it is left uncompressed automatically).
  fileSystems."/".options = [
    "noatime"
    "ssd"
    "space_cache=v2"
    "discard=async"
    "compress=zstd"
  ];

  # Periodic btrfs scrub to detect (and, with redundancy, repair) bit rot.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # Cap parallel builds: with only 16 GiB RAM, "auto" (= 16 jobs) can OOM or
  # thrash swap during heavy rebuilds. 4 jobs is a safe ceiling given zram.
  nix.settings.max-jobs = 4;

  # ---------------------------------------------------------------------------
  # Panel
  # ---------------------------------------------------------------------------
  host.display.internal = {
    output = "eDP-1";
    mode = "2880x1800";
    scale = "2";
    refreshRate = {
      ac = 120;
      battery = 60;
    };
  };

  # Quirks of this specific panel/APU combination, not of amdgpu in general.
  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
    "amdgpu.sg_display=0"
    "amdgpu.abmlevel=0"
  ];

  # ---------------------------------------------------------------------------
  # Power
  # ---------------------------------------------------------------------------
  services.tlp.settings = {
    # ACPI platform profile (driven by the ideapad_laptop driver). This lets
    # the EC manage power limits and fan curves alongside amd-pstate.
    # Choices on this laptop: low-power | balanced | performance.
    # Use "low-power" on battery for maximum endurance if you don't mind
    # reduced sustained performance.
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "balanced";

    # Battery charge threshold for IdeaPad (Conservation Mode via the
    # ideapad_laptop driver). 1 = stop charging at ~60% to extend battery
    # lifespan; set to 0 if you need full capacity for travel.
    STOP_CHARGE_THRESH_BAT0 = 1;
  };

  # ---------------------------------------------------------------------------
  # Gaming
  # ---------------------------------------------------------------------------
  # The 680M shares one power budget with the CPU. Pinning the DPM level to
  # "high" for the duration of a game removes the clock ramp-up latency
  # that causes stutter on short GPU bursts. If a CPU-bound title regresses
  # (the GPU then eats package TDP it does not need), set this to "auto".
  programs.gamemode.settings.gpu = {
    apply_gpu_optimisations = "accept-responsibility";
    gpu_device = 1; # /sys/class/drm/card1 — the Radeon 680M
    amd_performance_level = "high";
  };

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
