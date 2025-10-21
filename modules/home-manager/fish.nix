{ config, pkgs, ... }:

{
  home-manager.users.smn = {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
      shellAliases = {
        nrs = "sudo nixos-rebuild switch --use-remote-sudo --flake /home/smn/nixos-config#saymoon";
      };
    };
  };
  programs.fish.enable = true;
  users.users.smn.shell = pkgs.fish;
}
