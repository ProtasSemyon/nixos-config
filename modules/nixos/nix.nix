{ inputs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      # Required by logseq, which is pinned to an EOL Electron upstream.
      # Drop this (and logseq from home/packages.nix) to close the CVE exposure.
      "electron-39.8.10"
    ];
  };

  # Pin the system's <nixpkgs> / flake registry to the flake input.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;

    # Allow wheel users to use the configured binary caches and pass
    # trusted Nix options without sudo (root is always trusted).
    trusted-users = [ "@wheel" ];

    substituters = [
      "https://nix-community.cachix.org" # Community packages
      "https://hyprland.cachix.org"
      "https://nixos-cache-proxy.elxreno.com"
    ];

    trusted-substituters = [
      "https://cache.nixos.org" # Official global cache
      "https://nix-community.cachix.org" # Community packages
      "https://hyprland.cachix.org"
      "https://nixos-cache-proxy.elxreno.com"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];

    http-connections = 128;
  };

  # Garbage collection is handled by nh (programs.nh.clean), so the built-in
  # nix.gc timer is left disabled to avoid running two GC schedules.
  nix.gc.automatic = false;
}
