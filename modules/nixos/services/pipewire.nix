{ pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  home-manager.users.smn = {

    xdg.configFile."pipewire/pipewire.conf.d/99-deepfilternet.conf" = {
      text = builtins.toJSON {
        "context.properties" = {
          "link.max-buffers" = 16;
          "core.daemon" = true;
          "core.name" = "pipewire-0";
          "module.x11.bell" = false;
          "module.access" = true;
          "module.jackdbus-detect" = false;
        };

        "context.modules" = [
          {
            name = "libpipewire-module-filter-chain";
            args = {
              "node.description" = "DeepFilter Noise Canceling source";
              "media.name" = "DeepFilter Noise Canceling source";

              "filter.graph" = {
                nodes = [
                  {
                    type = "ladspa";
                    name = "DeepFilter Stereo";
                    plugin = "${pkgs.deepfilternet}/lib/ladspa/libdeep_filter_ladspa.so";
                    label = "deep_filter_stereo";
                    control = {
                      "Attenuation Limit (dB)" = 100;
                    };
                  }
                ];
              };

              "audio.rate" = 48000;
              "audio.channels" = 2;
              "audio.position" = "[FL FR]";

              "capture.props" = {
                "node.name" = "deep_filter_stereo_input";
                "media.class" = "Audio/Sink";
              };
              "playback.props" = {
                "node.name" = "deep_filter_stereo_output";
                "node.passive" = true;
              };
            };
          }
        ];
      };
    };
  };
}
