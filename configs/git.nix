{ ... }:

{ 
    programs.git = {
        enable = true;
        userName = "AngelYahir";
        userEmail = "angel.torres@aytcode.com";

        extraConfig = {
            init.defaultBranch = "master";
            pull.rebase = false;
            core.editor = "nvim";
            push.autoSetupRemote = true;
        };
    };
}