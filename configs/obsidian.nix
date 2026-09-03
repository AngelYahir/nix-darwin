{ config, lib, ... }:

let
    vault = "Documents/Obsidian/KnowledgeBase";
in
{
    programs.obsidian = {
        enable = true;

        vaults.knowledge = {
            target = vault;

            settings.app = {
                alwaysUpdateLinks = true;
                spellcheck = true;
                newFileLocation = "folder";
                newFileFolderPath = "00 Inbox";
                attachmentFolderPath = "Attachments";
            };
        };
    };

    home.activation.obsidianDirectories = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run mkdir -p \
            "${config.home.homeDirectory}/${vault}/00 Inbox" \
            "${config.home.homeDirectory}/${vault}/10 Projects/Trabajo1" \
            "${config.home.homeDirectory}/${vault}/10 Projects/Trabajo2" \
            "${config.home.homeDirectory}/${vault}/10 Projects/Personal" \
            "${config.home.homeDirectory}/${vault}/20 Engineering/Architecture" \
            "${config.home.homeDirectory}/${vault}/20 Engineering/Backend" \
            "${config.home.homeDirectory}/${vault}/20 Engineering/Security" \
            "${config.home.homeDirectory}/${vault}/20 Engineering/Infrastructure" \
            "${config.home.homeDirectory}/${vault}/20 Engineering/Decisions" \
            "${config.home.homeDirectory}/${vault}/30 Languages/Russian" \
            "${config.home.homeDirectory}/${vault}/30 Languages/Japanese" \
            "${config.home.homeDirectory}/${vault}/40 Personal" \
            "${config.home.homeDirectory}/${vault}/90 Templates" \
            "${config.home.homeDirectory}/${vault}/Attachments"
    '';
}
