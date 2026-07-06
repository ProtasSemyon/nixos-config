{ ... }:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    wireplumber.extraConfig."10-bluez" = {
      "monitor.bluez.properties" = {
        # Включаем все кодеки/профили для наушников и гарнитур.
        "bluez5.enable-sbc-xq" = true; # SBC-XQ (лучшее качество для A2DP)
        "bluez5.enable-msbc" = true; # mSBC — широкополосный звук для HFP/HSP
        "bluez5.enable-hw-volume" = true; # аппаратное управление громкостью
        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
          "hsp_hs"
          "hsp_ag"
          "hfp_hf"
          "hfp_ag"
        ];
      };
    };
  };
}
