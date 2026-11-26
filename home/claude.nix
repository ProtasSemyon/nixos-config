{ inputs, ... }:

{
  # Equivalent of `npx skills add blader/humanizer --global`, pinned by
  # flake.lock instead of fetched at runtime.
  home.file.".claude/skills/humanizer".source = inputs.humanizer;
}
