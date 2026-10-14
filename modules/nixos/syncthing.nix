{ lib, username, ... }:

let
  # Device IDs, printed by `syncthing device-id` on each machine once the
  # service has run. They are public, not secret. A host that is not listed
  # here simply does not take part yet, which is harmless.
  devices = {
    saymoon = "2AQBXNJ-BYVTVOJ-IYLIFIH-N2KW3A3-FA55B5S-ZQJAHRB-QLKWXU5-J2YD7AH";
    # fx505dd = "";
  };
in
{
  # Keeps the Minecraft instance in step between the laptops. Syncthing is
  # peer-to-peer, so neither machine is the server and sync happens whenever
  # both are up; Tailscale/Netbird mean that need not be the same LAN.
  #
  # Caveat worth remembering: a Minecraft world is a pile of binary region
  # files that no sync tool can merge. Never run the game on both machines at
  # once, and let the folder reach "Up to Date" before launching on the other
  # one. Staggered versioning below is the safety net if that goes wrong.
  services.syncthing = {
    enable = true;

    # Run as the user so the folder can live in their home.
    user = username;
    group = "users";
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";

    # 22000/tcp+udp for transfers, 21027/udp for local discovery.
    openDefaultPorts = true;

    # The declarative config wins; changes made in the web UI are reverted on
    # the next activation rather than silently diverging from this file.
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = lib.mapAttrs (_: id: { inherit id; }) devices;

      folders."divine-journey-2" = {
        label = "Divine Journey 2";
        path = "/home/${username}/.local/share/PrismLauncher/instances/Divine Journey 2";
        devices = lib.attrNames devices;

        # Keep superseded versions for a month under .stversions, thinning them
        # out as they age. A world clobbered by a bad sync is recoverable.
        versioning = {
          type = "staggered";
          params.maxAge = toString (30 * 24 * 60 * 60);
        };
      };
    };
  };
}
