{
  pkgs,
  ...
}:

let
  wallpapers = ./wp;

  wallpaperScript = pkgs.writeShellScriptBin "rotate-wallpaper" ''
    set -euo pipefail

    WALLPAPER_DIR="${wallpapers}"

    STATE_DIR="$HOME/Library/Application Support/nix-wallpaper"
    STATE_FILE="$STATE_DIR/index"

    mkdir -p "$STATE_DIR"

    mapfile -t FILES < <(
      ${pkgs.findutils}/bin/find "$WALLPAPER_DIR" \
        -type f \
        \( \
          -iname '*.jpg' -o \
          -iname '*.jpeg' -o \
          -iname '*.png' -o \
          -iname '*.heic' -o \
          -iname '*.webp' \
        \) \
        | ${pkgs.coreutils}/bin/sort
    )

    COUNT="''${#FILES[@]}"

    if [ "$COUNT" -eq 0 ]; then
      echo "No wallpapers found in $WALLPAPER_DIR"
      exit 1
    fi

    INDEX=0

    if [ -f "$STATE_FILE" ]; then
      INDEX="$(cat "$STATE_FILE")"
    fi

    INDEX=$((INDEX % COUNT))

    WALLPAPER="''${FILES[$INDEX]}"

    /usr/bin/osascript <<EOF
    tell application "System Events"
      tell every desktop
        set picture to POSIX file "$WALLPAPER"
      end tell
    end tell
EOF

    NEXT=$(((INDEX + 1) % COUNT))
    echo "$NEXT" > "$STATE_FILE"

    echo "Wallpaper: $WALLPAPER"
  '';
in
{
  home.packages = [
    wallpaperScript
  ];

  launchd.agents.wallpaper-rotation = {
    enable = true;

    config = {
      ProgramArguments = [
        "${wallpaperScript}/bin/rotate-wallpaper"
      ];

      RunAtLoad = true;

      # 15 minutos
      StartInterval = 900;

      ProcessType = "Background";

      StandardOutPath = "/tmp/nix-wallpaper.log";
      StandardErrorPath = "/tmp/nix-wallpaper.err.log";
    };
  };
}