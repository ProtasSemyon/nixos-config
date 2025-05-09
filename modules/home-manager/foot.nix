{ config, lib, pkgs, ... }:
{
  home-manager.users.smn = { config, lib, pkgs, ... }:
  {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          font =  "FiraCode Nerd Font Mono:size=14";

          term = "xterm-256color";
          dpi-aware = "yes";
        };

        colors = {
          background="282a36";
          foreground="f8f8f2";

          ## Normal/regular colors (color palette 0-7)
          regular0="21222c";  # black
          regular1="ff5555";  # red
          regular2="50fa7b";  # green
          regular3="f1fa8c";  # yellow
          regular4="bd93f9";  # blue
          regular5="ff79c6";  # magenta
          regular6="8be9fd";  # cyan
          regular7="f8f8f2";  # white

          ## Bright colors (color palette 8-15)
          bright0="6272a4";   # bright black
          bright1="ff6e6e";   # bright red
          bright2="69ff94";   # bright green
          bright3="ffffa5";   # bright yellow
          bright4="d6acff";   # bright blue
          bright5="ff92df";   # bright magenta
          bright6="a4ffff";   # bright cyan
          bright7="ffffff";   # bright white

          ## dimmed colors (see foot.ini(5) man page)
          # dim0=<not set>
          # ...
          # dim7=<not-set>

          ## The remaining 256-color palette
          # 16 = <256-color palette #16>
          # ...
          # 255 = <256-color palette #255>

          ## Misc colors
          selection-foreground="ffffff";
          selection-background="44475a";
          # jump-labels=<regular0> <regular3>          # black-on-yellow
          # scrollback-indicator=<regular0> <bright4>  # black-on-bright-blue
          # search-box-no-match=<regular0> <regular1>  # black-on-red
          # search-box-match=<regular0> <regular3>     # black-on-yellow
          urls="8be9fd";
        };

      };
    };
  };
}