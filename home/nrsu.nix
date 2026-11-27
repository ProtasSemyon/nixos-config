{ pkgs, ... }:

# nrsu: update every flake input, switch, publish the new lock, and move the
# project devshells along (home/dev-envs.nix).
#
# The lock is pulled first so an update pushed from another machine is built
# on rather than raced, and only flake.lock is committed: other uncommitted
# work in the repository stays untouched. The push goes over SSH; https
# pushes are refused here (see CLAUDE.md). A failed push leaves the commit
# local and says so; the switch itself has already happened.
let
  nrsu = pkgs.writeShellApplication {
    name = "nrsu";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
    ];
    text = ''
      repo="$HOME/nixos-config"

      if ! git -C "$repo" pull --ff-only --quiet; then
        echo "nrsu: could not fast-forward $repo; resolve that first." >&2
        exit 1
      fi

      old=$(git -C "$repo" show HEAD:flake.lock)

      nh os switch --update "$@"

      if git -C "$repo" diff --quiet -- flake.lock; then
        echo "nrsu: flake.lock unchanged, nothing to commit."
      else
        changes=$(jq -rn --argjson a "$old" --slurpfile b "$repo/flake.lock" '
          [ $b[0].nodes | to_entries[]
            | select(.key != "root")
            | .key as $k
            | { k: $k,
                o: ($a.nodes[$k].locked.rev // $a.nodes[$k].locked.narHash // "new"),
                n: (.value.locked.rev // .value.locked.narHash) }
            | select(.o != .n)
            | "\(.k): \(.o[0:12]) -> \(.n[0:12])" ]
          | join("\n")')
        git -C "$repo" commit --quiet -m "flake: update inputs" -m "$changes" -- flake.lock
        echo "nrsu: committed flake.lock:"
        printf '%s\n' "$changes" | sed 's/^/  /'
        if git -C "$repo" -c 'url.git@github.com:.insteadOf=https://github.com/' push --quiet origin HEAD; then
          echo "nrsu: pushed."
        else
          echo "nrsu: push failed; the commit is local, push it later." >&2
        fi
      fi

      # Hand the new system to the build cache now rather than at the next
      # hourly tick, so the other machines find it there when they pull this
      # lock. The unit exists only on cache clients, not on the cache host.
      systemctl --user start --no-block build-cache-push.service 2>/dev/null || true

      dev-envs-sync
    '';
  };
in
{
  home.packages = [ nrsu ];
}
