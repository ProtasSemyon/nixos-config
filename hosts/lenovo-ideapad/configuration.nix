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
    nix-conf.programs.steam
    nix-conf.programs.thunar

    nix-conf.services.pipewire

    hm.hyprland
    hm.waybar
    hm.fish
    hm.foot
    hm.git
    hm.vscode
  ];

  nixpkgs.overlays = [
    (final: prev: {
      ciscoPacketTracer8 = prev.ciscoPacketTracer8.overrideAttrs (old: {
        postFixup = ''
          wrapProgram $out/bin/packettracer8 \
          --unset QT_PLUGIN_PATH \
          --unset QT_QPA_PLATFORMTHEME \
          --set QT_QPA_PLATFORM_PLUGIN_PATH /opt/pt/lib/plugins/platforms \
          --set LD_LIBRARY_PATH /opt/pt/bin:/opt/pt/lib
        '';
      });
    })
  ];

  distro-grub-themes = {
    enable = true;
    theme = "nixos";
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_X11_EGL = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    LIBVA_DRIVER_NAME = "radeonsi";

    GOOGLE_CLOUD_PROJECT = "glass-chimera-478707-f5";
    GOOGLE_CLOUD_PROJECT_ID = "glass-chimera-478707-f5";
  };

  networking.hostName = "saymoon";

  networking.networkmanager.enable = true;

  services.resolved.enable = true;
  services.fwupd.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg0" ];
  };

  time.timeZone = "Europe/Minsk";

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-36.9.5"
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;

    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store" # Shanghai Jiao Tong University - best for Asia
      "https://mirrors.ustc.edu.cn/nix-channels/store" # USTC backup mirror
      "https://cache.nixos.org" # Official global cache
      "https://nix-community.cachix.org" # Community packages
      "https://hyprland.cachix.org"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
    ];

    trusted-substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store" # Shanghai Jiao Tong University - best for Asia
      "https://mirrors.ustc.edu.cn/nix-channels/store" # USTC backup mirror
      "https://cache.nixos.org" # Official global cache
      "https://nix-community.cachix.org" # Community packages
      "https://hyprland.cachix.org"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
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

  programs.adb.enable = true;
  programs.firefox.enable = true;
  programs.zen-browser.enable = true;

  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode - - - - 1"
  ];

  programs.wireshark.enable = true;
  programs.wireshark.dumpcap.enable = true;

  programs.direnv.enable = true;
  programs.direnv.enableFishIntegration = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    keyMap = "us";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.blueman.enable = true;

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
    vim
    wget
    btop
    mesa
    vulkan-tools
    pulseaudioFull
    pipewire
    wireplumber
    pamixer
    helvum

    obsidian

    #Nix stuff
    nix-prefetch-github

    #Theme
    sddm-astronaut
    catppuccin-sddm

    #Programming

    #C++
    gcc
    clang
    clang-tools
    lldb
    gdb
    cmake
    ninja
    gnumake
    pkg-config
    valgrind
    ccache

    dotnet-runtime

    slack

    docker-compose
    #jetbrains-toolbox

    wireguard-tools
    zed-editor

    volantes-cursors

    nixd
    nil

    nix-ld
    wireshark

    mpd-mpris

    libva
    libva-utils

    gemini-cli

    ciscoPacketTracer8
  ];

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
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "both";
  };

  networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];

  services.deluge = {
    enable = true;
    web.enable = true;
  };

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

  system.stateVersion = "25.05";
}
