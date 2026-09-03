{
    lib,
    pkgs,
    inputs,
    username,
    hostname,
    ...
}:

{
    nixpkgs.overlays = [
        (final: prev: {
            zjstatus = 
                inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;

            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (pythonFinal: pythonPrev: {
                    gradio =
                        (pythonPrev.gradio.overridePythonAttrs (old: {
                            # These mocks no longer intercept Gradio's requests,
                            # so the tests attempt access in the Nix sandbox.
                            disabledTests = (old.disabledTests or [ ]) ++ [
                                "test_sleep_successful"
                                "test_sleep_unsuccessful"
                            ];
                        }))
                        // {
                            # Gradio uses its own package-level override in a
                            # passthru test; overridePythonAttrs does not retain it.
                            inherit (pythonPrev.gradio) override;
                        };
                })
            ];
        })
    ];
    imports = [ 
        ./homebrew.nix
        ../configs/jankyborders.nix
        ../configs/aerospace.nix
        ../configs/fonts.nix
        ../configs/macos.nix
    ];

    nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
        "claude-code"
        "github-copilot-cli"
        "obsidian"
    ];

    nixpkgs.hostPlatform = "aarch64-darwin";
    system.primaryUser = username;
    networking.hostName = hostname;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    users.users.${username} = { home = "/Users/${username}"; };

    system.stateVersion = 7;
}
