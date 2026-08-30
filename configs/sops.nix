{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sops
    age
  ];

  sops = {
    age.keyFile =
      "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";

    defaultSopsFile = ../secrets/personal.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
      git-name = {
        key = "git/name";
      };

      git-email = {
        key = "git/email";
      };
    };

    templates."gitconfig.local".content = ''
      [user]
        name = "${config.sops.placeholder.git-name}"
        email = "${config.sops.placeholder.git-email}"
    '';
  };
}