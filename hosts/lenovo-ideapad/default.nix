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
  ];

  networking.hostName = "saymoon";
  time.timeZone = "Europe/Minsk";

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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs self username; };
    users.${username} = import ../../home;
  };

  system.stateVersion = "26.05";
}
