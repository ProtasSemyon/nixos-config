{ ... }:

{
  home-manager.users.smn = { pkgs, ... } : {
    programs.vscode = {
      enable = true;
      profiles.default = {
        enableUpdateCheck = true;
        enableExtensionUpdateCheck = true;
      };
      package = pkgs.vscode;
    }; 
  };
}
