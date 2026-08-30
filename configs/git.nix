{ config, ... }:

{ 
    programs.git = {
        enable = true;

        settings = {
            credential = {
                # Use the macOS keychain for storing Git credentials
                helper = "/Library/Developer/CommandLineTools/usr/libexec/git-core/git-credential-osxkeychain";
            };

            init.defaultBranch = "main";
            pull.rebase = false;
            core.editor = "nvim";
            push.autoSetupRemote = true;
            include.path = config.sops.templates."gitconfig.local".path;
        };

    };
}