{ ... }:

{
  virtualisation.docker = {
    enable = true;

    # Reclaim disk weekly: prunes build cache, dangling images, stopped
    # containers and unused networks. Named volumes and tagged images are kept.
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
