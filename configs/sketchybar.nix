{
    config,
    lib,
    pkgs,
    ...
}:

let
    cavaMediaConfig = pkgs.writeText "sketchybar-cava.conf" ''
        [general]
        bars = 10
        framerate = 20
        autosens = 1
        sensitivity = 100
        lower_cutoff_freq = 45
        higher_cutoff_freq = 14000

        [input]
        method = coreaudio
        source = tap

        [output]
        method = raw
        channels = stereo
        raw_target = /dev/stdout
        data_format = ascii
        ascii_max_range = 7
        bar_delimiter = 59
        frame_delimiter = 10

        [smoothing]
        noise_reduction = 77
        monstercat = 1
        waves = 0
    '';

    media-spectrum = pkgs.writeShellApplication {
        name = "sketchybar-media-spectrum";
        runtimeInputs = [ pkgs.cava pkgs.sketchybar ];
        text = ''
            state_dir="''${TMPDIR:-/tmp}/sketchybar-media-spectrum"
            pid_file="$state_dir/runner.pid"
            lock_dir="$state_dir/runner.lock"
            config_file="${cavaMediaConfig}"
            log_file="/tmp/sketchybar-media-spectrum.log"
            runner_fifo=""
            runner_cava_pid=""

            is_running() {
                local pid
                [[ -s "$pid_file" ]] || return 1
                pid=$(<"$pid_file")
                [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
            }

            stop_runner() {
                if is_running; then
                    local pid
                    pid=$(<"$pid_file")
                    kill "$pid" 2>/dev/null || true
                fi
            }

            start_runner() {
                mkdir -p "$state_dir"
                if is_running; then
                    return
                fi

                rm -f "$pid_file"
                rmdir "$lock_dir" 2>/dev/null || true
                if ! mkdir "$lock_dir" 2>/dev/null; then
                    return
                fi

                nohup "$0" run </dev/null >>"$log_file" 2>&1 &
                printf '%s\n' "$!" >"$pid_file"
            }

            render_frame() {
                local frame=$1
                local -a values glyphs
                local left="" right="" value index

                IFS=';' read -r -a values <<<"$frame"
                ((''${#values[@]} >= 10)) || return
                glyphs=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

                for ((index = 0; index < 5; index++)); do
                    value=''${values[index]}
                    [[ "$value" =~ ^[0-7]$ ]] || value=0
                    left+="''${glyphs[value]}"
                done

                for ((index = 5; index < 10; index++)); do
                    value=''${values[index]}
                    [[ "$value" =~ ^[0-7]$ ]] || value=0
                    right+="''${glyphs[value]}"
                done

                sketchybar \
                    --set center.media.spectrum.left label="$left" \
                    --set center.media.spectrum.right label="$right"
            }

            cleanup() {
                trap - EXIT INT TERM
                if [[ -n "$runner_cava_pid" ]]; then
                    kill "$runner_cava_pid" 2>/dev/null || true
                    wait "$runner_cava_pid" 2>/dev/null || true
                fi
                [[ -n "$runner_fifo" ]] && rm -f "$runner_fifo"
                if [[ -s "$pid_file" ]] && [[ "$(<"$pid_file")" == "$$" ]]; then
                    rm -f "$pid_file"
                fi
                rmdir "$lock_dir" 2>/dev/null || true
            }

            run_spectrum() {
                trap cleanup EXIT INT TERM

                mkdir -p "$state_dir"
                runner_fifo="$state_dir/cava.$$.fifo"
                mkfifo "$runner_fifo"
                cava -p "$config_file" >"$runner_fifo" 2>>"$log_file" &
                runner_cava_pid=$!

                while IFS= read -r frame; do
                    render_frame "$frame"
                done <"$runner_fifo"
            }

            case "''${1:-}" in
                start) start_runner ;;
                stop) stop_runner ;;
                run) run_spectrum ;;
                *) printf 'usage: %s {start|stop}\n' "$0" >&2; exit 2 ;;
            esac
        '';
    };

    media-marquee = pkgs.writeShellApplication {
        name = "sketchybar-media-marquee";
        runtimeInputs = [ pkgs.coreutils pkgs.sketchybar ];
        text = ''
            state_dir="''${TMPDIR:-/tmp}/sketchybar-media-marquee"
            pid_file="$state_dir/runner.pid"
            sleeper_pid=""

            is_running() {
                local pid
                [[ -s "$pid_file" ]] || return 1
                pid=$(<"$pid_file")
                [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
            }

            stop_runner() {
                if is_running; then
                    local pid
                    pid=$(<"$pid_file")
                    kill "$pid" 2>/dev/null || true
                else
                    rm -f "$pid_file"
                fi
            }

            start_runner() {
                local title=$1
                local max_chars=$2
                local pid attempt

                mkdir -p "$state_dir"
                if is_running; then
                    pid=$(<"$pid_file")
                    kill "$pid" 2>/dev/null || true
                    for ((attempt = 0; attempt < 20; attempt++)); do
                        kill -0 "$pid" 2>/dev/null || break
                        sleep 0.025
                    done
                fi

                nohup "$0" run "$title" "$max_chars" </dev/null >/dev/null 2>&1 &
                printf '%s\n' "$!" >"$pid_file"
            }

            pause_for() {
                sleep "$1" &
                sleeper_pid=$!
                wait "$sleeper_pid" 2>/dev/null || true
                sleeper_pid=""
            }

            cleanup() {
                trap - EXIT INT TERM
                if [[ -n "$sleeper_pid" ]]; then
                    kill "$sleeper_pid" 2>/dev/null || true
                    wait "$sleeper_pid" 2>/dev/null || true
                fi
                if [[ -s "$pid_file" ]] && [[ "$(<"$pid_file")" == "$$" ]]; then
                    rm -f "$pid_file"
                fi
            }

            run_marquee() {
                local title=$1
                local max_chars=$2
                local gap="   "
                local initial sequence window
                local length gap_length offset

                [[ "$max_chars" =~ ^[0-9]+$ ]] || exit 2
                export LC_ALL="''${LC_ALL:-en_US.UTF-8}"
                trap cleanup EXIT
                trap 'exit 0' INT TERM

                length=''${#title}
                ((length > max_chars)) || exit 0
                gap_length=''${#gap}
                initial=''${title:0:max_chars}
                sequence="$title$gap$title"

                sketchybar --set center.media label="$initial"
                pause_for 2

                while true; do
                    for ((offset = 1; offset <= length + gap_length; offset++)); do
                        window=''${sequence:offset:max_chars}
                        sketchybar --set center.media label="$window"
                        pause_for 0.12
                    done

                    sketchybar --set center.media label="$initial"
                    pause_for 3
                done
            }

            case "''${1:-}" in
                start)
                    (($# == 3)) || exit 2
                    start_runner "$2" "$3"
                    ;;
                stop) stop_runner ;;
                run)
                    (($# == 3)) || exit 2
                    run_marquee "$2" "$3"
                    ;;
                *) printf 'usage: %s {start <title> <max-chars>|stop}\n' "$0" >&2; exit 2 ;;
            esac
        '';
    };

    # nixpkgs still ships 1.2.1, whose direct MediaRemote access no longer works
    # reliably on recent macOS releases. 2.1.0 includes the helper used on
    # Sequoia/Tahoe, including browser sessions such as YouTube.
    nowplaying-cli = pkgs.nowplaying-cli.overrideAttrs (_: {
        version = "2.1.0";

        src = pkgs.fetchFromGitHub {
            owner = "kirtan-shah";
            repo = "nowplaying-cli";
            rev = "v2.1.0";
            hash = "sha256-jPW3WEq1ZhxBojMO+5WF8ohO1rLmlAJKGdh1HfSOR5s=";
        };

        installPhase = ''
            runHook preInstall
            make install PREFIX="$out"
            runHook postInstall
        '';
    });

    sketchybarHost = pkgs.runCommandCC "sketchybar-host" { } ''
        app="$out/SketchyBar.app"
        mkdir -p "$app/Contents/MacOS"

        $CC -std=c11 -Wall -Wextra -Werror -x c -o "$app/Contents/MacOS/SketchyBarHost" - <<'EOF'
        #include <errno.h>
        #include <pwd.h>
        #include <signal.h>
        #include <spawn.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <string.h>
        #include <sys/types.h>
        #include <sys/wait.h>
        #include <unistd.h>

        extern char **environ;

        static volatile sig_atomic_t child_pid = -1;

        static void forward_signal(int signal_number) {
            pid_t pid = (pid_t)child_pid;

            if (pid > 0) {
                kill(pid, signal_number);
            }
        }

        static const char *environment_or_passwd(
            const char *variable,
            const char *passwd_value
        ) {
            const char *value = getenv(variable);

            return value != NULL && value[0] != '\0' ? value : passwd_value;
        }

        int main(void) {
            const struct passwd *account = getpwuid(getuid());
            const char *home = environment_or_passwd(
                "HOME",
                account != NULL ? account->pw_dir : NULL
            );
            const char *user = environment_or_passwd(
                "USER",
                account != NULL ? account->pw_name : NULL
            );
            const char *path_format =
                "%s/.nix-profile/bin:"
                "/etc/profiles/per-user/%s/bin:"
                "/run/current-system/sw/bin:"
                "/opt/homebrew/bin:"
                "/usr/local/bin:"
                "/usr/bin:/bin:/usr/sbin:/sbin";
            struct sigaction action;
            char *path;
            char *child_arguments[] = { "sketchybar", NULL };
            pid_t pid;
            int path_length;
            int spawn_error;
            int status;

            if (home == NULL || user == NULL) {
                fputs("SketchyBarHost: unable to determine HOME or USER\n", stderr);
                return 1;
            }

            path_length = snprintf(NULL, 0, path_format, home, user);
            if (path_length < 0) {
                fputs("SketchyBarHost: unable to construct PATH\n", stderr);
                return 1;
            }

            path = malloc((size_t)path_length + 1);
            if (path == NULL) {
                perror("SketchyBarHost: malloc");
                return 1;
            }

            snprintf(path, (size_t)path_length + 1, path_format, home, user);
            if (setenv("PATH", path, 1) != 0) {
                perror("SketchyBarHost: setenv");
                free(path);
                return 1;
            }
            free(path);

            memset(&action, 0, sizeof(action));
            action.sa_handler = forward_signal;
            sigemptyset(&action.sa_mask);
            if (sigaction(SIGTERM, &action, NULL) != 0 ||
                sigaction(SIGINT, &action, NULL) != 0) {
                perror("SketchyBarHost: sigaction");
                return 1;
            }

            spawn_error = posix_spawnp(
                &pid,
                "sketchybar",
                NULL,
                NULL,
                child_arguments,
                environ
            );
            if (spawn_error != 0) {
                errno = spawn_error;
                perror("SketchyBarHost: posix_spawnp sketchybar");
                return 1;
            }

            child_pid = (sig_atomic_t)pid;
            while (waitpid(pid, &status, 0) == -1) {
                if (errno != EINTR) {
                    perror("SketchyBarHost: waitpid");
                    return 1;
                }
            }
            child_pid = -1;

            if (WIFEXITED(status)) {
                return WEXITSTATUS(status);
            }
            if (WIFSIGNALED(status)) {
                return 128 + WTERMSIG(status);
            }
            return 1;
        }
        EOF

        cat > "$app/Contents/Info.plist" <<'EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>dev.angelyahir.sketchybar</string>
            <key>CFBundleName</key>
            <string>SketchyBar</string>
            <key>CFBundleDisplayName</key>
            <string>SketchyBar</string>
            <key>CFBundleExecutable</key>
            <string>SketchyBarHost</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>LSUIElement</key>
            <true/>
            <key>NSAudioCaptureUsageDescription</key>
            <string>SketchyBar uses system audio for the CAVA spectrum visualizer.</string>
        </dict>
        </plist>
        EOF
    '';
in

{
    programs.sketchybar = {
        enable = true;

        extraPackages = with pkgs; [
            aerospace
            jq
            media-marquee
            media-spectrum
            nowplaying-cli
            yq
        ];

        configType = "lua";
        sbarLuaPackage = pkgs.sbarlua;

        service = {
            enable = false;
            errorLogFile = "/tmp/sketchybar.error.log";
            outLogFile = "/tmp/sketchybar.out.log";
        };

        config = {
            source = ./sketchybar;
            recursive = true;
        };
    };

    home.activation.installSketchyBarHost =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            APPLICATIONS_DIR="${config.home.homeDirectory}/Applications"
            TARGET="$APPLICATIONS_DIR/SketchyBar.app"

            $DRY_RUN_CMD /bin/mkdir -p "$APPLICATIONS_DIR"
            if [[ -e "$TARGET" || -L "$TARGET" ]]; then
                $DRY_RUN_CMD /bin/chmod -R u+w "$TARGET"
                $DRY_RUN_CMD /bin/rm -rf "$TARGET"
            fi
            $DRY_RUN_CMD /usr/bin/ditto \
                "${sketchybarHost}/SketchyBar.app" \
                "$TARGET"
            $DRY_RUN_CMD /bin/chmod -R u+w "$TARGET"
            $DRY_RUN_CMD /usr/bin/codesign \
                --force \
                --sign - \
                --timestamp=none \
                "$TARGET"
        '';

    launchd.agents.sketchybar-host = {
        enable = true;

        config = {
            ProgramArguments = [
                "${config.home.homeDirectory}/Applications/SketchyBar.app/Contents/MacOS/SketchyBarHost"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            ProcessType = "Interactive";
            StandardOutPath = "/tmp/sketchybar-host.out.log";
            StandardErrorPath = "/tmp/sketchybar-host.error.log";
        };
    };
}
