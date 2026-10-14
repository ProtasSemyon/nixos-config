{
  writeShellApplication,
  coreutils,
  gamescope,
  gawk,
  hyprland,
  jq,
}:

# gamescope cannot work out which display it was launched on. With no -W/-H it
# silently falls back to 1280x720, and -f does not change that. Reading the
# Wayland output size would not help either: Hyprland advertises eDP-1 at its
# *logical* size, so a scale-2 2880x1800 panel looks like 1440x900 to clients.
#
# So resolve the focused monitor's real pixel geometry up front and pass it in.
# Use as a command prefix: `gamescope-auto -- <game>` (Lutris), or
# `gamescope-auto -- %command%` (Steam launch options).
writeShellApplication {
  name = "gamescope-auto";

  runtimeInputs = [
    coreutils
    gamescope
    gawk
    hyprland
    jq
  ];

  text = ''
    # Game launchers prepend their own library paths to LD_LIBRARY_PATH — Lutris
    # puts the FHS sandbox's /lib there, and gamemoderun adds an LD_PRELOAD.
    # Those win over a Nix binary's RPATH, so the helpers below would load the
    # sandbox's older libstdc++ and die with "version `GLIBCXX_3.4.35' not
    # found". Strip both for the helpers only: the game itself genuinely needs
    # those paths, so the final exec is left untouched.
    clean() { env -u LD_LIBRARY_PATH -u LD_PRELOAD "$@"; }

    # Every run appends a line here. Launchers swallow stderr in ways that are
    # hard to predict (Lutris keeps it in a window of its own), so a file is the
    # only dependable way to find out afterwards what was decided, and why.
    log="''${XDG_RUNTIME_DIR:-/tmp}/gamescope-auto.log"
    note() { printf '%s %s\n' "$(clean date +%H:%M:%S)" "$*" >>"$log" 2>/dev/null || true; }

    # Fraction of the native resolution the game renders at; FSR upscales the
    # rest. This is the main lever on a 12 CU iGPU. Default is native.
    scale="''${GAMESCOPE_SCALE:-1.0}"

    # stderr is deliberately kept out of these captures: the loader and the
    # compositor both write warnings there, and one stray line is enough to make
    # the JSON unparseable. On failure the call is simply repeated for its
    # message, which costs nothing on a path that is already giving up.
    geom=""
    if monitors=$(clean hyprctl -j monitors 2>/dev/null); then
      # .width/.height are the mode in physical pixels, independent of .scale.
      # A 90/270 degree transform swaps them.
      if geom=$(clean jq -r '
        map(select(.focused)) | .[0] // empty
        | if (.transform % 2) == 1
          then "\(.height) \(.width) \(.refreshRate)"
          else "\(.width) \(.height) \(.refreshRate)"
          end' <<<"$monitors" 2>/dev/null); then
        [ -n "$geom" ] || note "no monitor reports itself focused (json ''${#monitors}B)"
      else
        note "jq failed on ''${#monitors}B of JSON: $(clean jq -r . <<<"$monitors" 2>&1 >/dev/null | head -c 200)"
        geom=""
      fi
    else
      note "hyprctl failed: $(clean hyprctl -j monitors 2>&1 >/dev/null | head -c 200)"
    fi

    if [ -z "$geom" ]; then
      note "falling back to bare gamescope"
      echo "gamescope-auto: could not resolve the focused monitor, see $log" >&2
      exec gamescope "$@"
    fi

    read -r width height refresh <<<"$geom"

    # Floor to an even number of pixels — odd render sizes upset chroma
    # subsampling in some upscalers.
    render_w=$(clean awk -v v="$width"  -v s="$scale" 'BEGIN { printf "%d", int(v * s / 2) * 2 }')
    render_h=$(clean awk -v v="$height" -v s="$scale" 'BEGIN { printf "%d", int(v * s / 2) * 2 }')

    args=(
      -W "$width" -H "$height"
      -w "$render_w" -h "$render_h"
      -r "$(printf '%.0f' "$refresh")"
      -f
    )

    # FSR only does anything when the game renders below the output size.
    if [ "$render_w" -lt "$width" ]; then
      args+=(-F fsr)
    fi

    note "resolved ''${width}x''${height}@''${refresh} render ''${render_w}x''${render_h} scale=$scale"
    exec gamescope "''${args[@]}" "$@"
  '';
}
