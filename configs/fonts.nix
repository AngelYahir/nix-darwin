{ pkgs, ... }:

{
    fonts.packages = with pkgs; [
        # Fonts
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.hack
        nerd-fonts.iosevka
    ];
}