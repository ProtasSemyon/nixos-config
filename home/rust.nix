{ pkgs, ... }:

{
  home.packages = [ pkgs.sccache ];

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

  # Bound the shared sccache cache (default dir ~/.cache/sccache) so it can't
  # grow without limit — LRU eviction keeps it at ~20 GiB.
  home.file.".config/sccache/config".text = ''
    [cache.disk]
    size = 21474836480
  '';
}
