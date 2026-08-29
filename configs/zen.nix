{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  #Change for your profile name use `about:profiles` in firefox to find your profile name
  profile = "Library/Application Support/zen/Profiles/qazw21f4.Default (release)";

  catppuccinZen =
    "${inputs.catppuccin-zen}/themes/Mocha/Mauve";
in
{
  home.file = {
    "${profile}/chrome/userChrome.css".source =
      "${catppuccinZen}/userChrome.css";

    "${profile}/chrome/userContent.css".source =
      "${catppuccinZen}/userContent.css";

    "${profile}/chrome/zen-logo-mocha.svg".source =
      "${catppuccinZen}/zen-logo-mocha.svg";
  };

  home.activation.zenUserChrome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PROFILE="${config.home.homeDirectory}/${profile}"
    USER_JS="$PROFILE/user.js"

    mkdir -p "$PROFILE"
    touch "$USER_JS"

    PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

    if ${pkgs.gnugrep}/bin/grep -q \
      'toolkit.legacyUserProfileCustomizations.stylesheets' \
      "$USER_JS"; then

      ${pkgs.gnused}/bin/sed -i \
        's/user_pref("toolkit\.legacyUserProfileCustomizations\.stylesheets", [^)]*);/user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);/' \
        "$USER_JS"
    else
      echo "$PREF" >> "$USER_JS"
    fi
  '';
}