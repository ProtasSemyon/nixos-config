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
  home.file.".cargo/config.toml".text = ''
    [build]
    rustc-wrapper = "sccache"
    incremental = false
  '';

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
