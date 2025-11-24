{ pkgs, lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      ciscoPacketTracer8 = prev.ciscoPacketTracer8.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.makeWrapper ];
        postFixup = ''
          wrapProgram $out/bin/packettracer8 \
            --unset QT_PLUGIN_PATH \
            --unset QT_QPA_PLATFORMTHEME \
            --set QT_QPA_PLATFORM_PLUGIN_PATH /opt/pt/lib/plugins/platforms \
            --set LD_LIBRARY_PATH /opt/pt/bin:/opt/pt/lib
        '';
      });
    })
  ];

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      packettracer8 = {
        executable = lib.getExe pkgs.ciscoPacketTracer8;
        desktop = "${pkgs.ciscoPacketTracer8}/share/applications/cisco-pt8.desktop.desktop";
        extraArgs = [
          "--net=none"
          "--noprofile"
        ];
      };
    };
  };
}
