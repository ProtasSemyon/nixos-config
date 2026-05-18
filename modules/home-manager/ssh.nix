{ ... }:

{
  home-manager.users.smn = { pkgs, ... } : {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "office" = {
          hostname = "192.168.5.2";
          user = "saymoon";
          identityFile = "~/.ssh/home-laptop";
        };
      };
    };
  };
}
