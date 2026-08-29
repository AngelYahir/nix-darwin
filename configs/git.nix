{ ... }:

{ 
    programs.git = {
        enable = true;

        settings = {
            user = {
                name = "AngelYahir";
                email = "angel.torres@aytcode.com";
            };

            credential = {
                helper = "/usr/bin/git-credential-osxkeychain";
            };

            init.defaultBranch = "master";
            pull.rebase = false;
            core.editor = "nvim";
            push.autoSetupRemote = true;
        };

    };
}