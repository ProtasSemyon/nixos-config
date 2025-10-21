{ config, pkgs, ... }:

{
  home-manager.users.smn = { pkgs, ... } : {
    programs.git = {
      enable = true;
      settings = {
        user.name  = "Semyon Protas";
        user.email = "semyon.protas@gmail.com";
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
