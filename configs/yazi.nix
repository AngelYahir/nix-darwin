{
  pkgs, 
  inputs, 
  ...
}:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };

    extraPackages = with pkgs; [
      jq
      fd
      ripgrep
      fzf
      zoxide
      poppler
      imagemagick
      ffmpeg
    ];
  };
}