{ config, lib, ... }:
let
  wallpapersDir = ./wallpaper;
  availableWallpapers = builtins.attrNames (builtins.readDir wallpapersDir);
in
{
  options.hyprpaper = {
    enable = lib.mkEnableOption "Enable wallpaper configuration via Hyprpaper";

    wallpaper = lib.mkOption {
      type = lib.types.enum availableWallpapers;
      default = builtins.head availableWallpapers;
      description = ''
        Name of the wallpaper to use from ${toString wallpapersDir}.
        Available wallpapers: ${lib.concatStringsSep ", " availableWallpapers}.
      '';
    };
  };

  config = lib.mkIf config.hyprpaper.enable {
    home-manager.users.smn = {
      services.hyprpaper = {
        enable = true;
        settings = {
          splash = false;
          preload = [
            "${wallpapersDir}/${config.hyprpaper.wallpaper}"
          ];
          wallpaper = [
            {
              monitor = "";
              path = "${wallpapersDir}/${config.hyprpaper.wallpaper}";
            }
          ];
        };
      };
    };
  };
}
