{ pkgs, inputs, ...}:
{
  home-manager.users.smn = {
    programs.waybar = {
      enable = true;
    };
    home.file.".config/waybar".source = "${inputs.dotfiles}/waybar";
  };
}