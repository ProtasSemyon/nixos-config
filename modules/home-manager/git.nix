{ config, pkgs, ... }:

{
  home-manager.users.smn = { pkgs, ... } : {
    programs.git = {
      enable = true;
      userName  = "Semyon Protas";
      userEmail = "semyon.protas@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
        core.autocrlf = true;
      };
    }; 

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };
  };
}