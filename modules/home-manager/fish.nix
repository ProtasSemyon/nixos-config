{ config, pkgs, ... }:

{
  home-manager.users.smn = {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';   
    };
  };
  programs.fish.enable = true;
  users.users.smn.shell = pkgs.fish;
}
