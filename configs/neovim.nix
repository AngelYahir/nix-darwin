{ inputs, pkgs, ... }:
{
  home.packages = [ pkgs.nodejs ];

  # Keep the config directory writable so Lazy can maintain lazy-lock.json.
  xdg.configFile = {
    "nvim/init.lua".source = "${inputs.foxy-nvim}/init.lua";
    "nvim/lua".source = "${inputs.foxy-nvim}/lua";
    "nvim/plugin".source = "${inputs.foxy-nvim}/plugin";
    "nvim/logos".source = "${inputs.foxy-nvim}/logos";
  };
}
