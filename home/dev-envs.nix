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
# After re-locking, every devShell of every env is built into a profile under
# ~/.local/state/dev-envs, the way nix-direnv does it. That roots the shells
# against garbage collection, makes the first cd into a project after an
# update instant, and gives build-cache-push (modules/nixos/build-cache.nix)
# something to hand to the other machines.
#
# `nrsu` (home/nrsu.nix) runs this after updating the system. Missing
# directories are skipped, so machines without these projects are unaffected;
# one env failing to build does not stop the others.
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
      system=$(nix eval --raw --impure --expr builtins.currentSystem)
      state="$HOME/.local/state/dev-envs"
      mkdir -p "$state"
      echo "system nixpkgs: $rev"

      failed=0
      for e in ${toString envs}; do
        d="$HOME/$e"
        [ -f "$d/flake.nix" ] || continue
        name=$(basename "$d")
        echo "-> $name"
        (cd "$d" && nix flake lock --override-input nixpkgs "github:NixOS/nixpkgs/$rev")

        shells=$(nix eval --json "$d#devShells.$system" --apply builtins.attrNames | jq -r '.[]')
        for shell in $shells; do
          profile="$state/$name-$shell"
          if nix develop "$d#$shell" --profile "$profile" --command true; then
            nix-env --profile "$profile" --delete-generations old >/dev/null
            echo "   built $name#$shell"
          else
            echo "   FAILED $name#$shell" >&2
            failed=1
          fi
        done
      done
      exit "$failed"
    '';
  };
in
{
  home.packages = [ dev-envs-sync ];
}
