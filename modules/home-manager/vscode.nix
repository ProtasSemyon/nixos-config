{ ... }:

{
  home-manager.users.smn =
    { pkgs, ... }:
    {
      programs.vscode = {
        enable = false;
        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = true;
        };
        package = pkgs.vscode;
      };
    };
}
