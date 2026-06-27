{ pkgs, username, ... }:

{
  programs.fish.enable = true;
  users.users.${username}.shell = pkgs.fish;

  programs.direnv.enable = true;
  programs.direnv.enableFishIntegration = true;

  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };
}
