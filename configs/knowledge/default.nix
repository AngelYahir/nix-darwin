{ config, pkgs, ... }:

let
  kb = pkgs.buildGoModule {
    pname = "kb";
    version = "0.1.0";
    src = ./gateway;
    vendorHash = null;
    nativeCheckInputs = [ pkgs.git ];

    subPackages = [
      "cmd/kb"
      "cmd/kb-agent"
      "cmd/kb-gateway"
    ];

    checkPhase = ''
      runHook preCheck
      go test ./...
      runHook postCheck
    '';
  };
in
{
  home.packages = [ kb ];

  xdg.configFile."kb/policy.toml".source = ./policy.toml;

  launchd.agents.kb-gateway = {
    enable = true;

    config = {
      ProgramArguments = [ "${kb}/bin/kb-gateway" ];
      EnvironmentVariables.HOME = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "/tmp/kb-gateway.out.log";
      StandardErrorPath = "/tmp/kb-gateway.error.log";
    };
  };
}
