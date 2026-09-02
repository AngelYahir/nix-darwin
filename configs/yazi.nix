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

      # Force PDFs through Yazi's built-in PDF renderer even when `file`
      # reports a generic MIME type (common with some downloaded PDFs).
      plugin = {
        prepend_preloaders = [
          { url = "*.pdf"; run = "pdf"; }
        ];
        prepend_previewers = [
          { url = "*.pdf"; run = "pdf"; }
        ];
      };
    };

    extraPackages = with pkgs; [
      jq
      fd
      ripgrep
      fzf
      zoxide
      poppler-utils
      resvg
      imagemagick
      ffmpeg
    ];
  };
}
