{ config, lib, pkgs, inputs, system, self, ... }:
let 
  hm = import ../../modules/home-manager;
  nix-conf = import ../../modules/nixos;
in 
{
  imports =
    [ 
      ./hardware-configuration.nix
      nix-conf.boot
      nix-conf.programs.steam
      
      hm.hyprland
      hm.fish
      hm.foot
      hm.git
      hm.vscode
    ];
    
  networking.hostName = "saymoon"; 

  networking.networkmanager.enable = true; 

  time.timeZone = "Europe/Minsk";

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    delete_generations = "+5"; # Option added by nix-gc-env
  };

  programs.adb.enable = true;
  programs.firefox.enable = true;

  #Thunar
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
  #Thunar

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    keyMap = "us";
  };


  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.smn = {
    isNormalUser = true;
    extraGroups = [ "wheel" "network" "kvm" "adbusers" ];
  };

  home-manager = {
    extraSpecialArgs = { 
      inherit inputs; 
      inherit system; 
      inherit self; 
    };
    useGlobalPkgs = true;
    users = {
      "smn" = import ./home.nix;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim 
    wget
    direnv    
    mesa 
    vulkan-tools
    brightnessctl
  ];

  fonts.packages = [ pkgs.nerdfonts ];
  fonts.fontconfig.useEmbeddedBitmaps = true;
  # List services that you want to enable:

  services.openssh.enable = true;
  services.tailscale.enable = true;

  system.stateVersion = "24.11";
}

