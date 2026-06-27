{ config, ... }:

{
  programs.waybar.enable = true;

  # Symlink straight to the repo so waybar tweaks (config.jsonc / style.css)
  # apply on save without a rebuild.
  home.file.".config/waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/dotfiles/waybar";
}
