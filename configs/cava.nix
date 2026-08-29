{ ... }:

{
  programs.cava = {
    enable = true;

    settings = {
      general = {
        framerate = 60;
        bar_width = 2;
        bar_spacing = 1;
      };

      input = {
        method = "coreaudio";
        source = "tap";
      };

      output = {
        method = "ncurses";
        channels = "stereo";
      };

      smoothing = {
        noise_reduction = 77;
      };
    };
  };

  catppuccin.cava = {
    transparent = true;
  };

}