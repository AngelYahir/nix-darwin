{ inputs, pkgs, ... }:
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
        lua5_1
        lua5_1.pkgs.luarocks
        python314

        #containers
        colima
        docker # includes docker compose

        #networking
        httpie
        nmap

        #json
        grpcurl

        #archives
        unzip
        zip
        zathura

        #mail
        aerc

        #images
        pngpaste
        imagemagick
        rembg
        ffmpeg
        exiftool
        chafa
        ghostscript

        #rust
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer
        cargo-watch
        bacon

        #go
        go
        gopls
        delve
        golangci-lint
        air

        #AI
        github-copilot-cli
        inputs.herdr.packages.${pkgs.system}.default
    ];
}
