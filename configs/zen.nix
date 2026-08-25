{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  catppuccinZen =
    "${inputs.catppuccin-zen}/themes/Mocha/Mauve";
in
{
  home.activation.catppuccinZen =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ZEN_ROOT="${config.home.homeDirectory}/Library/Application Support/zen"
      PROFILES_INI="$ZEN_ROOT/profiles.ini"

      if [ ! -f "$PROFILES_INI" ]; then
        echo "Zen Browser profile not found."
        echo "Open Zen once and run home-manager/darwin-rebuild again."
      else
        PROFILE_PATH="$(
          ${pkgs.gawk}/bin/awk '
            /^\[Profile[0-9]+\]$/ {
              if (in_profile && is_default && path != "") {
                print path
                exit
              }

              in_profile = 1
              is_default = 0
              path = ""
              next
            }

            /^\[/ {
              if (in_profile && is_default && path != "") {
                print path
                exit
              }

              in_profile = 0
            }

            in_profile && /^Path=/ {
              sub(/^Path=/, "")
              path = $0
            }

            in_profile && /^Default=1$/ {
              is_default = 1
            }

            END {
              if (in_profile && is_default && path != "") {
                print path
              }
            }
          ' "$PROFILES_INI" | head -n 1
        )"

        # Fallback: primer perfil si no existe Default=1
        if [ -z "$PROFILE_PATH" ]; then
          PROFILE_PATH="$(
            ${pkgs.gawk}/bin/awk -F= '
              /^Path=/ {
                print $2
                exit
              }
            ' "$PROFILES_INI"
          )"
        fi

        if [ -z "$PROFILE_PATH" ]; then
          echo "Could not determine Zen profile."
        else
          PROFILE="$ZEN_ROOT/$PROFILE_PATH"
          CHROME="$PROFILE/chrome"

          mkdir -p "$CHROME"

          ln -sfn \
            "${catppuccinZen}/userChrome.css" \
            "$CHROME/userChrome.css"

          ln -sfn \
            "${catppuccinZen}/userContent.css" \
            "$CHROME/userContent.css"

          ln -sfn \
            "${catppuccinZen}/zen-logo-mocha.svg" \
            "$CHROME/zen-logo-mocha.svg"

          USER_JS="$PROFILE/user.js"

          PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

          touch "$USER_JS"

          if ! grep -Fq \
            'toolkit.legacyUserProfileCustomizations.stylesheets' \
            "$USER_JS"; then

            echo "$PREF" >> "$USER_JS"
          fi

          echo "Catppuccin Mocha Mauve configured for Zen:"
          echo "$PROFILE"
        fi
      fi
    '';
}