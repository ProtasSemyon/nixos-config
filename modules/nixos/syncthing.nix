{ lib, username, ... }:

let
  # Device IDs, printed by `syncthing device-id` on each machine once the
  # service has run. They are public, not secret. A host that is not listed
  # here simply does not take part yet, which is harmless.
  #
  # `addresses` lists where to dial a device besides "dynamic" (local and
  # global discovery, then relays). office is always on and always on the
  # tailnet, so it is tried there first; without Tailscale, discovery still
  # finds it.
  devices = {
    saymoon.id = "2AQBXNJ-BYVTVOJ-IYLIFIH-N2KW3A3-FA55B5S-ZQJAHRB-QLKWXU5-J2YD7AH";
    fx505dd.id = "XIVYMEK-IZQZMJR-2XFTQ4Z-AU6AAJP-V3T2DG3-OJCARUC-6Q5ORTH-IXPZSAG";
    office = {
      id = "KZWR54K-C5L3WQ3-SDRUVEE-HCR3KR2-HZKJFGO-JPWWPXS-VC7UEEC-KNJJCQB";
      addresses = [
        "tcp://office.tail883758.ts.net:22000"
        "quic://office.tail883758.ts.net:22000"
        "dynamic"
      ];
    };
  };

  # Keep superseded versions under .stversions for `days`, thinning them out
  # as they age.
  staggered = days: {
    type = "staggered";
    params.maxAge = toString (days * 24 * 60 * 60);
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
      inherit devices;

      folders."divine-journey-2" = {
        label = "Divine Journey 2";
        path = "/home/${username}/.local/share/PrismLauncher/instances/Divine Journey 2";
        # Only the machines the game is played on; office would just carry
        # 5 GiB it never uses.
        devices = [
          "saymoon"
          "fx505dd"
        ];

        # A world clobbered by a bad sync is recoverable for a month.
        versioning = staggered 30;
      };

      # The KeePassXC databases. office is the always-on peer, so an edit made
      # on one laptop reaches the other even when the two are never up at the
      # same time.
      #
      # The files are encrypted by KeePassXC; Syncthing only carries them. If
      # a database is edited on two machines while they cannot see each other,
      # Syncthing keeps both as `*.sync-conflict-*.kdbx` -- fold the extra one
      # back in with KeePassXC's Database > Merge from database.
      folders.passwords = {
        label = "Passwords";
        path = "/home/${username}/Passwords";
        devices = lib.attrNames devices;

        # A database lost or overwritten is recoverable for a year.
        versioning = staggered 365;
      };
    };
  };
}
