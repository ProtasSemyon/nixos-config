{ pkgs, ... }:

{
  programs.thunar.enable = true;
  programs.xfconf.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-media-tags-plugin
    thunar-dropbox-plugin
    thunar-vcs-plugin
    thunar-volman
    tumbler    
  ];
  
  services.gvfs.enable = true; 
  services.tumbler.enable = true; 
  services.udisks2.enable = true;
  
  environment.systemPackages = with pkgs; [
    gvfs                       # trash, network mounts, smb:// support
    ffmpegthumbnailer          # video thumbnails
    poppler                    # PDF thumbnails
    freetype
    file-roller                # GUI archive manager
    p7zip zip unzip unrar      # archive backends
    exiftool                   # metadata support
    
    adwaita-icon-theme
    papirus-icon-theme
    gnome-themes-extra
  ];
  
  home-manager.users.smn = {
    home.file.".config/xfce4/helpers.rc".text = ''
      TerminalEmulator=foot
    '';
  };
}
