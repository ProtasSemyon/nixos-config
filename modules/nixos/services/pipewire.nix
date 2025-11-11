{
  pkgs,
  ...
}:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig = {
      pipewire = {
        "10-rnnoise" = {
          "context.modules" = [
            {
              "name" = "libpipewire-module-filter-chain";
              "args" = {
                "node.description" = "Noise Canceling source";
                "media.name" = "Noise Canceling source";
                "filter.graph" = {
                  "nodes" = [
                    {
                      "type" = "ladspa";
                      "name" = "rnnoise";
                      "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                      "label" = "noise_suppressor_mono";
                      "control" = {
                        "VAD Threshold (%)" = 90.0;
                        "VAD Grace Period (ms)" = 350;
                        "Retroactive VAD Grace (ms)" = 80;
                      };
                    }
                  ];
                };
                "capture.props" = {
                  "node.name" = "effect_input.rnnoise";
                  "node.passive" = true;
                  "audio.rate" = 48000;
                  "audio.channels" = 1;
                  "audio.position" = [ "MONO" ];
                  "stream.dont-remix" = true;
                };
                "playback.props" = {
                  "node.name" = "effect_output.rnnoise";
                  "media.class" = "Audio/Source";
                  "audio.rate" = 48000;
                  "audio.channels" = 1;
                  "audio.position" = [ "MONO" ];
                };
              };
            }
          ];
        };
        "20-echo-cancellation" = {
          "context.modules" = [
            {
              "name" = "libpipewire-module-echo-cancel";
              "args" = {
                "library.name" = "aec/libspa-aec-webrtc";
                "aec.args" = {
                  "webrtc.extended_filter" = true;
                  "webrtc.delay_agnostic" = true;
                  "webrtc.high_pass_filter" = true;
                  "webrtc.noise_suppression" = false;
                  "webrtc.voice_detection" = false;
                  "webrtc.gain_control" = false;
                  "webrtc.experimental_agc" = false;
                  "webrtc.experimental_ns" = false;
                };
                "node.latency" = "1024/48000";
                # monitor.mode = false
                # https://docs.pipewire.org/page_module_echo_cancel.html:
                #
                # .--------.     .---------.     .--------.     .----------.     .-------.
                # | source | --> | capture | --> |        | --> |  source  | --> |  app  |
                # '--------'     '---------'     | echo   |     '----------'     '-------'
                #                                | cancel |
                # .--------.     .---------.     |        |     .----------.     .--------.
                # |  app   | --> |  sink   | --> |        | --> | playback | --> |  sink  |
                # '--------'     '---------'     '--------'     '----------'     '--------'
                #
                "capture.props" = {
                  # Cancel this sound out, should be un-cancelled mic input
                  "node.description" = "Echo Cancel Capture";
                  "node.name" = "echo_cancel.mic.input";
                  "target.object" = "effect_input.rnnoise";
                };
                "sink.props" = {
                  # Cancel sound out of this, should be set to system's default output so all apps' output will be cancelled
                  "node.description" = "Echo Cancel Sink";
                  "node.name" = "echo_cancel.playback.input";
                };
                "source.props" = {
                  # Echo-cancelled mic input, should be set to system's default input so all apps' mic input will be cancelled
                  "node.description" = "Echo Cancel Source";
                  "node.name" = "echo_cancel.mic.output";
                };
                "playback.props" = {
                  # Echo-cancelled sound output, this should be a hardware speaker, if left unassigned it intelligently chooses one
                  "node.description" = "Echo Cancel Playback";
                  "node.name" = "echo_cancel.playback.output";
                };
              };
            }
          ];
        };
      };
    };
  };
}
