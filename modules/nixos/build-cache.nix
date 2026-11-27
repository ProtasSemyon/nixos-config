{
  config,
  lib,
  pkgs,
  username,
  ...
}:

# Shared build caches, hosted on one machine and used by all of them.
# Compilation stays on each machine; the cache host only stores and serves.
#
#   Nix      Every client pushes its system closure to the cache host after
#            building it; harmonia serves the host's store, signed, so the
#            other machines substitute those paths instead of rebuilding.
#   sccache  A WebDAV share on the cache host is the second level of each
#            machine's sccache (see home/rust.nix), behind a local disk cache.
#
# Everything listens on the cache host's Tailscale address only in practice:
# the ports are not opened in the firewall, and tailscale0 is a trusted
# interface (modules/nixos/networking.nix).
let
  cfg = config.buildCache;
  isServer = cfg.server.enable;
  inherit (cfg) host;

  # The push runs unattended, so it cannot use the passphrase-protected
  # personal keys. It has its own key (private half in sops), which the cache
  # host accepts for exactly two things: the Nix daemon protocol, and rooting
  # one pushed path per machine. No shell, no forwarding.
  pushPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxmqaEPXO05W5sVWYZB1mTbYhBO4VASeEN2R8rM05ht build-cache-push";

  pushGate = pkgs.writeShellScript "build-cache-push-gate" ''
    case "$SSH_ORIGINAL_COMMAND" in
      "nix-daemon --stdio")
        exec ${config.nix.package}/bin/nix-daemon --stdio
        ;;
      "build-cache-root "*)
        # shellcheck disable=SC2086
        set -- $SSH_ORIGINAL_COMMAND
        name=$2 path=$3
        case "$name" in "" | *[!A-Za-z0-9-]*) exit 1 ;; esac
        case "$path" in /nix/store/*) ;; *) exit 1 ;; esac
        roots="$HOME/.local/state/build-cache-roots"
        ${pkgs.coreutils}/bin/mkdir -p "$roots"
        exec ${config.nix.package}/bin/nix-store --realise --add-root "$roots/$name" "$path" >/dev/null
        ;;
      *)
        echo "build-cache-push key: command not allowed" >&2
        exit 1
        ;;
    esac
  '';
in
{
  options.buildCache = {
    host = lib.mkOption {
      type = lib.types.str;
      default = "office.tail883758.ts.net";
      description = "MagicDNS name of the machine that hosts the caches.";
    };

    nixPort = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      readOnly = true;
      description = "Port harmonia serves the Nix binary cache on.";
    };

    sccachePort = lib.mkOption {
      type = lib.types.port;
      default = 6065;
      readOnly = true;
      description = "Port of the sccache WebDAV share.";
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
      default = "office-cache-1:djkNCfo+m/lsq3rG8X9KbRjylu0PzwpWqD0JJjoDmww=";
      readOnly = true;
      description = "Public half of the cache signing key (secret in sops).";
    };

    server = {
      enable = lib.mkEnableOption "hosting the shared caches on this machine";

      sccacheDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/sccache";
        description = "Where the sccache WebDAV share keeps its objects.";
      };

      sccacheMaxAgeDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 60;
        description = ''
          Cache objects older than this are deleted daily. The WebDAV backend
          has no eviction of its own, and an object is never rewritten on a
          hit, so this is age since it was stored, not since it was last used.
        '';
      };
    };
  };

  config = lib.mkMerge [
    # --- every machine except the host: use the cache, feed it ------------
    (lib.mkIf (!isServer) {
      nix.settings = {
        # Priority 50 sits after cache.nixos.org (40): public paths keep
        # coming from the CDN, office supplies what only we have built.
        substituters = [ "http://${host}:${toString cfg.nixPort}?priority=50" ];
        trusted-public-keys = [ cfg.publicKey ];
        # Off the tailnet the host cannot be reached; give up quickly and
        # build or fetch elsewhere instead of stalling every substitution.
        connect-timeout = 5;
        fallback = true;
      };

      sops.secrets.build-cache-push-key = {
        owner = username;
        mode = "0400";
      };

      # Push the running system to the cache host. `-s` lets the host fetch
      # whatever the public caches have by itself, so only what was built
      # here crosses the tailnet. The result is rooted on the host per machine,
      # or its garbage collection would drop it again.
      #
      # `-F none` keeps the user's ssh config (and its passphrase-protected
      # identities) out of it; host keys still come from /etc/ssh.
      systemd.user.services.build-cache-push = {
        description = "Push this machine's system closure to the build cache";
        unitConfig.ConditionUser = username;
        path = [
          config.nix.package
          pkgs.openssh
        ];
        environment.NIX_SSHOPTS = "-F none -i ${config.sops.secrets.build-cache-push-key.path} -o IdentitiesOnly=yes -o BatchMode=yes";
        serviceConfig.Type = "oneshot";
        script = ''
          system=$(readlink -f /run/current-system)
          nix copy -s --to "ssh-ng://${username}@${host}" "$system"
          # shellcheck disable=SC2086
          ssh $NIX_SSHOPTS "${username}@${host}" "build-cache-root ${config.networking.hostName} $system"
        '';
      };

      systemd.user.timers.build-cache-push = {
        description = "Push the system closure to the build cache hourly";
        unitConfig.ConditionUser = username;
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnStartupSec = "10min";
          OnUnitActiveSec = "1h";
        };
      };
    })

    # --- the host ----------------------------------------------------------
    (lib.mkIf isServer {
      sops.secrets.harmonia-signing-key = { };

      users.users.${username}.openssh.authorizedKeys.keys = [
        ''restrict,command="${pushGate}" ${pushPublicKey}''
      ];

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.sops.secrets.harmonia-signing-key.path ];
        settings.bind = "[::]:${toString cfg.nixPort}";
      };

      # hacdias/webdav. No users declared means no authentication; access is
      # limited to the tailnet by the firewall instead.
      services.webdav = {
        enable = true;
        settings = {
          address = "0.0.0.0";
          port = cfg.sccachePort;
          directory = cfg.server.sccacheDir;
          permissions = "CRUD";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.server.sccacheDir} 0750 ${config.services.webdav.user} ${config.services.webdav.group} -"
      ];

      systemd.services.sccache-prune = {
        description = "Drop old objects from the shared sccache";
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.findutils}/bin/find ${cfg.server.sccacheDir} -type f -mtime +${toString cfg.server.sccacheMaxAgeDays} -delete
          ${pkgs.findutils}/bin/find ${cfg.server.sccacheDir} -mindepth 1 -type d -empty -delete
        '';
      };

      systemd.timers.sccache-prune = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    })
  ];
}
