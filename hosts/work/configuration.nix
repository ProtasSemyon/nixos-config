{
  lib,
  pkgs,
  inputs,
  system,
  self,
  config,
  ...
}:
let
  hm = import ../../modules/home-manager;
  nix-conf = import ../../modules/nixos;
  edid = import ./edid;
in
{
  imports = [
    ./hardware-configuration.nix
    edid
    nix-conf.boot
    nix-conf.programs.thunar

    nix-conf.services.pipewire

    hm.hyprland
    hm.waybar
    hm.fish
    hm.foot
    hm.git
    hm.vscode
  ];

  distro-grub-themes = {
    enable = true;
    theme = "nixos";
  };

  networking.hostName = "saymoon";
  networking.networkmanager.enable = true;

  services.resolved.enable = true;
  services.fwupd.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.firewall.checkReversePath = "loose";

  time.timeZone = "Europe/Minsk";

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;

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
    ];

    http-connections = 128;
    max-jobs = "auto";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    delete_generations = "+5"; # Option added by nix-gc-env
  };

  programs.firefox.enable = true;
  programs.zen-browser.enable = true;

  # programs.wireshark.enable = true;
  # programs.wireshark.dumpcap.enable = true;

  programs.direnv.enable = true;
  programs.direnv.enableFishIntegration = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.smn = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "kvm"
      "adbusers"
      "docker"
      "wireshark"
    ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit system;
      inherit self;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users = {
      "smn" = import ./home.nix;
    };
  };

  # List packages installed in system ple. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    appimage-run
    vim
    wget
    btop

    pulseaudioFull
    pipewire
    wireplumber
    pamixer

    #Nix stuff
    nix-prefetch-github

    #Theme
    sddm-astronaut
    catppuccin-sddm

    slack

    docker-compose

    wireguard-tools

    volantes-cursors

    nixd
    nil

    nix-ld

    pinentry-gtk2
    toybox

    libva
    libva-utils

    clang
  ];

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };

  virtualisation.docker.enable = true;

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    qt5.qtbase
  ];

  fonts.packages = [
    pkgs.font-awesome
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  fonts.fontconfig.useEmbeddedBitmaps = true;
  # List services that you want to enable:

  services.openssh.enable = true;

  programs.command-not-found.enable = false;

  programs.nix-index = {
    enable = true;

    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva
      libvdpau
      libvdpau-va-gl
      libva-vdpau-driver
      libva-utils
    ];
  };

  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "25.11";
}
