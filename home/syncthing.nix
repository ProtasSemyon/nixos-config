{
  lib,
  osConfig,
  username,
  ...
}:

let
  # Derived from the NixOS module so the path cannot drift between the two.
  # home.file keys are relative to $HOME.
  instancePath = osConfig.services.syncthing.settings.folders."divine-journey-2".path;
  folder = lib.removePrefix "/home/${username}/" instancePath;
in
{
  # Patterns Syncthing applies to the instance. Writing this through Home
  # Manager also guarantees the directory exists, which Syncthing needs before
  # it will take the folder on a fresh machine.
  home.file."${folder}/.stignore".text = ''
    // Rolling world backups written by the pack's backup mod -- 26 GiB of the
    // instance's 31 GiB here. They regenerate on each machine and exist to be a
    // local safety copy, so syncing them would dominate the transfer for no
    // benefit.
    /minecraft/backups

    // Minecraft holds this for as long as a world is open. Syncing it makes the
    // other machine believe the world is still in use.
    session.lock

    // Rewritten on every launch.
    /minecraft/logs
    /minecraft/crash-reports
    *.log
    *.log.*

    // Local caches and extracted natives.
    .cache
    natives
  '';
}
