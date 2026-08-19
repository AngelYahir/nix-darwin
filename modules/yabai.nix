{ ... }:
{
  services.yabai = {
    enable = true;
    enableScriptingAddition = false; # keep scripting addition disabled (rootless)

    # Keep the actual yabai configuration in the repo-managed yabairc to
    # avoid duplicating settings inline in the main module.
    extraConfig = builtins.readFile ../config/yabai/yabairc;
  };
}
