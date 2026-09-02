{ pkgs, ... }:
{
    home.packages = with pkgs; [
        #Unix
        coreutils
        findutils
        gnused

        #cli
        ripgrep
        fd
        jq
        yq
        tree
        wget
        curl

        #modern Unix
        eza
        fzf
        zoxide
        bat
        neovim

        #monitoring
        btop

        #dev
        git
        gh
        lazygit

        #networking
        httpie
        nmap

        #json
        grpcurl

        #archives
        unzip
        zip

        #images
        pngpaste
        imagemagick
        rembg
        ffmpeg
        exiftool
    ];
}
