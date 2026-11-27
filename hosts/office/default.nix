{
  inputs,
  self,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos
  ];

  networking.hostName = "office";
  time.timeZone = "Europe/Minsk";

  # ---------------------------------------------------------------------------
  # Storage
  # ---------------------------------------------------------------------------
  # Layout and mount options live in ./disko.nix. The system SSD is small
  # (240 GB), so bulky data — docker volumes, datasets, backups — belongs on
  # the HDD at /data.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [
      "/"
      "/data"
    ];
  };

  # i5-8400: 6 cores, no SMT, 16 GiB.
  nix.settings.max-jobs = 4;

  # ---------------------------------------------------------------------------
  # Desktop that mostly acts as a server
  # ---------------------------------------------------------------------------
  # Reachable over SSH/Tailscale at any time, so it never goes to sleep —
  # whether asked to by the idle daemon, the power button, or by accident.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
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
