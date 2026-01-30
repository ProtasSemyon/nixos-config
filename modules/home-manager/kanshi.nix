{ pkgs, ... }:
{
  home-manager.users.smn = {
    services.kanshi = {
      enable = true;
      profiles = {
        office-workstation.outputs = [
          {
            criteria = "Dell Inc. DELL U2412M YPPY0725080S";
            status = "enable";
            mode = "1920x1200@59.95000Hz";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "2880x1800@120Hz";
            position = "0,1200";
          }
        ];
        home-workstation.outputs = [
          {
            criteria = "Dell Inc. DELL P2418D MY3ND93M0GXT";
            status = "enable";
            mode = "2560x1440@59.95Hz";
            position = "0,2880";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "2880x1800@120Hz";
            position = "0,0";
          }
        ];
        undocked.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "2880x1800@120Hz";
            position = "0,0";
          }
        ];
      };
    };
    home.packages = [
      pkgs.kanshi
    ];
  };
}
