{ lib, osConfig, ... }:

# C/C++ builds share the caches on the cache host (modules/nixos/build-cache.nix),
# the same way Rust does in home/rust.nix.
#
# These are only defaults in the environment. Project devshells (cpp-env via
# direnv) add their own variables on top without clearing these; a project
# that sets one of them itself, or a CMake preset's cacheVariables, wins.
# The endpoint stays out of the project repos on purpose: it only resolves on
# this tailnet.
let
  cache = osConfig.buildCache;
  webdav = "http://${cache.host}:${toString cache.sccachePort}";

  vars = {
    # Read by CMake when a build directory is configured for the first time;
    # an existing build/ keeps whatever its CMakeCache.txt already has.
    # sccache's config (two-level: local disk, then the share) is in
    # home/rust.nix. Hits across machines rely on identical paths, which the
    # shared username, ~/projects layout and the pinned cpp-env compiler give.
    CMAKE_C_COMPILER_LAUNCHER = "sccache";
    CMAKE_CXX_COMPILER_LAUNCHER = "sccache";

    # vcpkg's own binary cache: packages it has built are kept as archives and
    # reused when the ABI hash matches. Local ~/.cache/vcpkg first, then the
    # share. Flat file names: a WebDAV PUT into a missing directory fails.
    # With the host unreachable vcpkg warns and builds the port itself.
    VCPKG_BINARY_SOURCES = "clear;default,readwrite;http,${webdav}/vcpkg-{name}-{sha}.zip,readwrite";
  };
in
{
  home.sessionVariables = vars;

  # home.sessionVariables are sourced once per login session (guarded by
  # __HM_SESS_VARS_SOURCED, inherited from the graphical session), so a value
  # added by a switch stays invisible in new terminals until the next login.
  # A build that silently runs without them just rebuilds everything, so fish
  # sets these on every start as well.
  programs.fish.shellInit = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (n: v: "set -gx ${n} ${lib.escapeShellArg v}") vars
  );
}
