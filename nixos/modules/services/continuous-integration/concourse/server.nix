{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.concourse-web;
in
{
  options.services.concourse-web = {
    enable = lib.mkEnableOption "A container-based automation system written in Go. (The web server part)";
    package = lib.mkPackageOption pkgs "concourse" { };
    environment = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.str;
      example = lib.literalExpression ''
        {
          CONCOURSE_POSTGRES_HOST=127.0.0.1 # default
          CONCOURSE_POSTGRES_PORT=5432      # default
          CONCOURSE_POSTGRES_DATABASE=atc   # default
          CONCOURSE_POSTGRES_USER=my-user
          CONCOURSE_POSTGRES_PASSWORD=my-password
        }
      '';
      description = "Concourse web server environment variables [documentation](https://concourse-ci.org/concourse-web.html#web-running)";
    };
    environmentFile = lib.mkOption {
      type = with lib.types; coercedTo path (f: [ f ]) (listOf path);
      default = [ ];
      example = [ "/root/concourse-web.env" ];
      description = ''
        File to load environment variables
        from. This is helpful for specifying secrets.
        Example content of environmentFile:
        ```
        CONCOURSE_POSTGRES_PASSWORD=********
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      concourse-web = {
        description = "Concourse CI web";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          DynamicUser = true;
          WorkingDirectory = "%S/concourse-web";
          StateDirectory = "concourse-web";
          StateDirectoryMode = "0700";
          UMask = "0007";
          ConfigurationDirectory = "concourse-web";
          EnvironmentFile = cfg.environmentFile;
          ExecStart = "${cfg.package}/bin/concourse-web";
          Restart = "on-failure";
          RestartSec = 15;
          CapabilityBoundingSet = "";
          # Security
          NoNewPrivileges = true;
          # Sandboxing
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          PrivateMounts = true;
          # System Call Filtering
          SystemCallArchitectures = "native";
          SystemCallFilter = "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
        };
        inherit (cfg) environment;
      };
    };
  };

}
