{ pkgs, ... }:

let
  palette = {
    rosewater = "F5E0DC";
    flamingo = "F2CDCD";
    pink = "F5C2E7";
    mauve = "CBA6F7";
    red = "F38BA8";
    peach = "FAB387";
    yellow = "F9E2AF";
    green = "A6E3A1";
    teal = "94E2D5";
    sky = "89DCEB";
    blue = "89B4FA";
    lavender = "B4BEFE";
    text = "CDD6F4";
    overlay = "6C7086";
  };

  line = count: builtins.concatStringsSep "" (builtins.genList (_: "─") count);

  section = color: title: extension: {
    type = "custom";
    format = "{##${color}}╭─ ${title}${extension}{#}";
  };

  item = type: icon: label: color: value: extra: {
    inherit type;
    key = "${icon}  ${label}";
    keyColor = "#${color}";
    outputColor = "#${palette.text}";
    format = value;
  } // extra;

  # Fastfetch supports a left offset but not automatic centering. Keep the
  # 76-column layout centered while falling back to zero padding in narrow or
  # non-interactive terminals. User arguments come last and can override it.
  centeredFastfetch = pkgs.writeShellApplication {
    name = "fastfetch";
    runtimeInputs = [ pkgs.ncurses ];
    text = ''
      terminal_width="$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || true)"
      layout_width=76

      if [[ "$terminal_width" =~ ^[0-9]+$ ]] && (( terminal_width > layout_width )); then
        left_padding=$(( (terminal_width - layout_width) / 2 ))
      else
        left_padding=0
      fi

      exec ${pkgs.fastfetch}/bin/fastfetch --logo-padding-left "$left_padding" "$@"
    '';
  };
in
{
  programs.fastfetch = {
    enable = true;
    package = centeredFastfetch;

    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      # Keep the Rei motif from the legacy config without depending on a
      # terminal-specific image protocol or a mutable file in ~/.config.
      logo = {
        type = "data";
        source = ''
          $1⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⢀⣄⠠⠄⠄⣀⠀⠀⠀⠀⠀⠀⠀⠀
          ⠀⠀⠀⠀⠀⠀⠀⡀⠀⠁⠀⠀⠀⠈⠣⡶⠠⠁⢈⠂⢄⠀⠀⠀⠀⠀
          ⠀⠀⠀⠀⠀⢀⠞⠁⠀⠀⠀⠀⢀⡀⠀⠈⢖⢂⠤⡈⠀⢕⢄⠀⠀⠀
          ⠀⠀⠀⠀⢠⢁⢴⠃⠀⢀⣤⠖⠁⠀⢀⠔⠉⠀⢁⠀⠑⠀⢙⢦⠀⠀
          ⠀⠀⠀⠀⡾⣡⠃⢰⢈⠞⢓⢀⠆⢀⠆⠀⡆⠘⡀⡗⢆⡗⢅⡈⢆⠀
          ⠀⠀⠀⢠⡕⠇⠀⣇⠶⢠⣣⢊⢠⠃⠀⢸⠀⠀⠀⡇⢲⠫⡇⠇⡈⡆
          ⠀⠀⠀⠈⠱⣠⡇⠇⠒⣾⢡⠾⢸⠀⢀⠆⠀⠀⢄⣿⢸⠀⣱⡃⣅⡇
          ⠀⠀⠀⠀⢤⣇⢸⡆⢰⣿⣷⣒⣧⢧⡜⣠⡞⣼⣮⣿⡇⣰⣥⣧⢹⠇
          ⠀⠀⠀⠀⠈⢿⣖⢇⣾⡍⠛⠃⠈⣼⠿⢻⠟⠿⠇⣹⣿⣿⢻⠇⠈⠀
          ⠀⠀⠀⠀⠀⠀⢙⣿⣗⢽⣗⠤⠘⠁⠐⡁⠀⠤⣾⣿⣿⣿⠀⠀⠀⠀
          ⠀⠀⠀⠀⠀⢀⠞⠉⠀⠈⠉⢳⠦⠤⠬⠁⢒⣾⣿⣿⡟⡏⠀⠀⠀⠀
          ⠀⠀⠀⢀⡰⠁⠀⠀⠀⠀⠀⠈⣧⣀⠄⠚⢿⠿⠋⠘⠀⠀⠀⠀⠀⠀
          ⠀⠠⠂⣵⠁⣠⣿⡿⡆⠀⠀⠀⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ⢀⣁⣸⣿⠀⢯⠗⠘⠁⠀⠀⢸⣷⡄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ⢨⢠⣿⣿⠀⠀⠁⠀⠀⠀⣶⡏⢻⣧⡈⠑⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        '';
        color."1" = "#${palette.pink}";
        padding = {
          top = 1;
          right = 3;
        };
      };

      display = {
        separator = "  →  ";
        color = {
          keys = "#${palette.mauve}";
          title = "#${palette.teal}";
          output = "#${palette.text}";
          separator = "#${palette.overlay}";
        };
        key = {
          type = "string";
          width = 22;
        };
        bar = {
          width = 10;
          char = {
            elapsed = "━";
            total = "─";
          };
        };
        percent = {
          type = 9;
          color = {
            green = "#${palette.green}";
            yellow = "#${palette.yellow}";
            red = "#${palette.red}";
          };
        };
        duration.abbreviation = true;
      };

      modules = [
        (section palette.sky "SYSTEM" " ${line 38}")
        (item "os" "" "macOS" palette.blue "{codename} {version}" { })
        (item "host" "󰌢" "Host" palette.rosewater "{name}" { })
        (item "cpu" "" "CPU" palette.peach "{name}" { })
        (item "memory" "" "Memory" palette.green "{used} / {total}" { })
        "break"

        (section palette.mauve "ENVIRONMENT" "")
        (item "custom" "" "WM" palette.mauve "AeroSpace" { })
        (item "custom" "" "Terminal" palette.pink "Ghostty" { })
        (item "custom" "" "Shell" palette.lavender "zsh" { })
        (item "custom" "" "Multiplexer" palette.flamingo "Zellij" { })
        (item "custom" "" "Nix" palette.blue "nix-darwin" { })
        "break"

        (section palette.green "STATUS" "")
        (item "uptime" "󰅐" "Uptime" palette.green "{formatted}" { })
        (item "packages" "󰏗" "Packages" palette.mauve "{nix-all} Nix · {brew-all} Brew" { })
        (item "disk" "󰋊" "Disk" palette.teal "{size-used} used · {size-percentage}" {
          folders = "/";
        })
        {
          type = "custom";
          format = "{##${palette.green}}╰${line 47}{#}";
        }
      ];
    };
  };
}
