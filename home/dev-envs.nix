{ pkgs, ... }:

# The shared project devshells (direnv: `use flake ../rust-env` and the like)
# lock nixpkgs to exactly the revision the running system was built from.
# Their packages then are the system's own store paths, or ones the build
# cache already has, instead of a second nixpkgs to download and build.
#
# flake.nix keeps the ordinary github: URL; only flake.lock is moved. (An
# indirect `nixpkgs.url = "nixpkgs"` does not work for this: inputs resolve
# through the global registry, not the system one nixos-config pins.)
#
# `nrsu` runs this after updating the system; nix-direnv notices the changed
# lock and reloads the shell on the next cd. Missing directories are skipped,
# so machines without these projects are unaffected.
let
  envs = [
    "projects/rust_projects/rust-env"
    "projects/cpp_projects/cpp-env"
    "projects/js_projects/js-env"
    "projects/python/python-env"
  ];

  dev-envs-sync = pkgs.writeShellApplication {
    name = "dev-envs-sync";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      rev=$(nixos-version --json | jq -r .nixpkgsRevision)
      echo "system nixpkgs: $rev"
      for e in ${toString envs}; do
        d="$HOME/$e"
        [ -f "$d/flake.nix" ] || continue
        echo "-> $e"
        (cd "$d" && nix flake lock --override-input nixpkgs "github:NixOS/nixpkgs/$rev")
      done
    '';
  };
in
{
  home.packages = [ dev-envs-sync ];
}
