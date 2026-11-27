{ osConfig, pkgs, ... }:

let
  cache = osConfig.buildCache;
in
{
  # rustup provides the cargo/rustc/rustup proxies on PATH for every login and
  # graphical session (home-manager is a NixOS module, so this lands in
  # /etc/profiles/per-user and is visible to GUI apps like Zed, which compile
  # Rust extensions themselves). The actual toolchains live in ~/.rustup.
  home.packages = [
    pkgs.rustup
    pkgs.sccache
  ];

  # Route every cargo build through sccache so identical crates (same version,
  # features, flags, toolchain) are compiled once and reused across all
  # projects and git worktrees — flake-based or not. Lives in the shared
  # ~/.cargo home, so it applies globally.
  # incremental is disabled because sccache does not cache incremental builds.
  #
  # Debug info is most of a dev build's target/. Own code keeps line tables
  # (file:line in backtraces and panics), dependencies get none: stepping
  # into a dependency in a debugger shows no locals, own code is unaffected.
  # A project's own [profile.dev] in Cargo.toml takes precedence.
  home.file.".cargo/config.toml".text = ''
    [build]
    rustc-wrapper = "sccache"
    incremental = false

    [profile.dev]
    debug = "line-tables-only"

    [profile.dev.package."*"]
    debug = false
  '';

  # target/ never shrinks by itself: old crate versions, dropped features and
  # past toolchains pile up. Weekly, drop artifacts older than two weeks
  # across ~/projects. The filesystem is mounted noatime, so "older" means
  # built longer ago, not unused for longer; anything still needed is rebuilt,
  # mostly from sccache.
  systemd.user.services.cargo-sweep = {
    Unit.Description = "Remove stale cargo build artifacts under ~/projects";
    Service = {
      Type = "oneshot";
      Environment = "PATH=${pkgs.rustup}/bin";
      ExecStart = "${pkgs.cargo-sweep}/bin/cargo-sweep sweep --recursive --time 14 %h/projects";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.cargo-sweep = {
    Unit.Description = "Weekly cargo-sweep of ~/projects";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Two levels: a bounded local disk cache answers first, the WebDAV share on
  # the cache host (modules/nixos/build-cache.nix) is shared by every machine.
  # A local miss that hits the share is copied back to disk.
  home.file.".config/sccache/config".text = ''
    [cache.disk]
    size = 10737418240

    [cache.webdav]
    endpoint = "http://${cache.host}:${toString cache.sccachePort}"

    [cache.multilevel]
    chain = ["disk", "webdav"]
  '';
}
