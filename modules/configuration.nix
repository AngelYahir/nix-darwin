
{ config, pkgs, ... }: {
  imports = [
    ./yabai.nix
  ];
  # Nix-darwin platform
  nixpkgs.hostPlatform = "aarch64-darwin";  # o "x86_64-darwin"

  # Base
  programs.zsh.enable = true;

  #skhd window manager
  services.skhd = {
    enable = true;
  };

  services.sketchybar = {
    enable = true;
  };

  # Flakes & nix-command
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    build-users-group = "nixbld";
    build-dir = "/nix/var/nix/build";
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = config.rev or config.dirtyRev or null;

  # It'll be fine trust me
  nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.config.allowUnfree = true;

  # Required for nix-darwin
  system.stateVersion = 6;

  # Set primary user (required for user-specific settings)
  system.primaryUser = "angel";

  system.activationScripts.extraActivation.text = ''
    if [ -f "/Users/angel/.config/homebrew/trust.json" ]; then
      mkdir -p "/Users/angel/.homebrew"
      ln -sfn "/Users/angel/.config/homebrew/trust.json" "/Users/angel/.homebrew/trust.json"
      chown -h angel "/Users/angel/.homebrew/trust.json"
      chown angel "/Users/angel/.homebrew"
    fi

    if [ -x "/opt/homebrew/bin/brew" ]; then
      PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" \
      sudo \
        --preserve-env=PATH \
        --user=angel \
        --set-home \
        env XDG_CONFIG_HOME="/Users/angel/.config" \
        brew trust --tap felixkratz/formulae || true

      PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" \
      sudo \
        --preserve-env=PATH \
        --user=angel \
        --set-home \
        env XDG_CONFIG_HOME="/Users/angel/.config" \
        brew trust --tap danielgatis/imgcat || true

      PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" \
      sudo \
        --preserve-env=PATH \
        --user=angel \
        --set-home \
        env XDG_CONFIG_HOME="/Users/angel/.config" \
        brew trust --tap hacker1024/hacker1024 || true
    fi
  '';

  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 54;
      show-recents = false;
      minimize-to-application = false;
    };

    # Finder settings
    finder = {
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # List view
    };

    # NSGlobalDomain settings
    NSGlobalDomain = {
      # Keyboard settings
      KeyRepeat = 2; # Fast key repeat
      InitialKeyRepeat = 15; # Short delay until repeat

      # Interface settings
      AppleInterfaceStyle = "Dark"; # Dark mode
      AppleShowAllExtensions = true; # Show all file extensions
      "_HIHideMenuBar" = true; # Auto-hide menu bar
    };

    # Screenshots settings
    screencapture = {
      location = "$HOME/Desktop/Screenshots"; # Save to ~/Desktop/Screenshots
      type = "png"; # Save as PNG
    };

    # Login window settings
    loginwindow.GuestEnabled = false; # Disable guest account
  };

  # System packages
  fonts.packages = with pkgs; [ 
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.meslo-lg
    nerd-fonts.iosevka
    nerd-fonts.zed-mono
    nerd-fonts.iosevka-term
  ];
}
