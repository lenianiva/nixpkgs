{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.concourse-worker;
in
{
  meta.maintainers = with lib.maintainers; [ lenianiva ];

  options.services.concourse-worker = {
    enable = lib.mkEnableOption "A container-based automation system written in Go. (The worker part)";
    package = lib.mkPackageOption pkgs "concourse" { };
    tag = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Tag for this worker";
    };
    team = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Team for this worker";
    };
    work-dir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/concourse";
      description = "Work directory, which should be backed by sufficient storage.";
    };
    tsa = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:2222";
        description = "Host";
      };
      public-key = lib.mkOption {
        type = lib.types.str;
        description = "Public key";
      };
      worker-private-key = lib.mkOption {
        type = lib.types.str;
        description = "Private key for this worker";
      };
    };
    extra-options = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra options to pass to concourse executable";
    };
    environment = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.str;
      example = lib.literalExpression ''
        {
          CONCOURSE_CONTAINERD_DNS_SERVER="1.1.1.1,8.8.8.8";
        }
      '';
      description = "Concourse web server environment variables [documentation](https://concourse-ci.org/concourse-worker.html#web-running)";
    };
    environmentFile = lib.mkOption {
      type = with lib.types; coercedTo path (f: [ f ]) (listOf path);
      default = [ ];
      example = [ "/root/concourse-worker.env" ];
      description = ''
        File to load environment variables
        from. This is helpful for specifying secrets.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      concourse-worker = {
        description = "Concourse CI worker";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          # Worker must be run as root, because it needs to launch containers
          User = "root";
          #WorkingDirectory = cfg.work-dir;
          StateDirectory = cfg.work-dir;
          StateDirectoryMode = "0700";
          UMask = "0007";
          ConfigurationDirectory = "concourse-worker";
          EnvironmentFile = cfg.environmentFile;
          ExecStart = "${cfg.package}/bin/concourse worker ${cfg.extra-options}";
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
        environment = {
          CONCOURSE_WORK_DIR = cfg.work-dir;
          CONCOURSE_TAG = cfg.tag;
          CONCOURSE_TEAM = cfg.team;

          CONCOURSE_TSA_HOST = cfg.tsa.host;
          CONCOURSE_TSA_PUBLIC_KEY = cfg.tsa.public-key;
          CONCOURSE_TSA_WORKER_PRIVATE_KEY = cfg.tsa.worker-private-key;
        }
        // cfg.environment;
      };
    };
  };

}
