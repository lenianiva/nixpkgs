{
  config,
  lib,
  pkgs,
  ...
}:
let
  concoursePackage = pkgs.concourse;
  username = "concourse";
  database = "concourse";
  password = "mypass";
  tsa-host-key-pub = pkgs.writeTextFile {
    name = "tsa-host-key-pub";
    text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDobnbljTPx+qONY4DSjKGgekPJK/Qcyby0mtW/AXHKXqiKIB9tleOApI8cj8fXTIIj0JfvelggPH+fc60XO5D/svMuZN+rPDf9CyGb4vujvGiG8hJSXRFhqHaaT+YS79u65eEdyOOSbiMxzi3WS5AJ1XAKSNIrFtK84UQ7oAAhww== test@example.org";
  };
  tsa-host-key = pkgs.writeTextFile {
    name = "tsa-host-key";
    text = ''
      -----BEGIN RSA PRIVATE KEY-----
      MIICXAIBAAKBgQDobnbljTPx+qONY4DSjKGgekPJK/Qcyby0mtW/AXHKXqiKIB9t
      leOApI8cj8fXTIIj0JfvelggPH+fc60XO5D/svMuZN+rPDf9CyGb4vujvGiG8hJS
      XRFhqHaaT+YS79u65eEdyOOSbiMxzi3WS5AJ1XAKSNIrFtK84UQ7oAAhwwIDAQAB
      AoGABFSSiIJR9m8p/udcrg+Kr1e3zZaxDJxBlMfRtaZMPW34C+K/UyZYv7vRIsIX
      Ag7d2db4DbEk1SzrX8gi8GzeravKaXetjuAZEGcy26135QGE4EOeyHRS15yIxn/E
      Ik/bcM7HFOktrtJny/y8Fqou+DHlrrQ5DBc7NxQ179AlKEECQQD8/p07tXx3JL/p
      mbEMpFDq4B3q+TR3LYcGFQePugoAdp6FuMlgaeSY2ogh4tYZymzI5ZiMDb3Lr9z6
      5jAeLAbjAkEA6zFQxmhWQkHjjJ1UOtwms8kIRLrAkzhcwb/qRtp1iwSGoS03oSt5
      Zgg2qmPd9k3Q3S6x6htfMAaBQIUJml2PoQJAWp4QT3y38iz1mIR2SCLq4NYZoTpV
      soJaJLGPnclzH6tdKGSBrMkBGkbcD9ch/ObmhCbItxGM89IwAqZEgeofJQJAbP/l
      BJ70Yy6wK8n6cHD5Stc/isLWXyR+8JhmFkJGuY/2aRpQrtQ8Jgpmc19nTjBQPUHX
      2Lyox9Qr8N/3TGBSIQJBAKhogPmaRYCvGFe3mWsRdhaeDrRg5lbB0TC3MPYR/Vov
      OCSM3EeS6Qctz3qujJnFznPhgY5AgRB+Y+Ca7oYFEpw=
      -----END RSA PRIVATE KEY-----
    '';
  };
in
{
  name = concoursePackage.pname;
  meta.maintainers = with lib.maintainers; [
    lenianiva
  ];

  nodes = {
    server =
      { config, pkgs, ... }:
      {
        virtualisation.memorySize = 2047;

        users = {
          users.${config.services.concourse-web.user} = {
            description = "Concourse service";
            isSystemUser = true;
            group = "staff";
            useDefaultShell = true;
          };
          groups.staff = {
            name = "staff";
            members = [
              "admin"
              username
              "postgres"
            ];
          };
        };
        services = {
          openssh.enable = true;
          concourse-web = {
            enable = true;
            postgres = {
              inherit database password;
              user = username;
            };
            keys = {
              tsa-host = "${tsa-host-key}";
            };
            environment = {
              CONCOURSE_ADD_LOCAL_USER = "${username}:${password}";
              CONCOURSE_MAIN_TEAM_LOCAL_USER = username;
            };
          };
          postgresql = {
            enable = true;
            ensureDatabases = [ database ];
            ensureUsers = [
              {
                name = username;
                ensureDBOwnership = true;
              }
            ];
            authentication = ''
              # type database db-user auth-method map
              local ${username} ${username} peer map=concourse-map
            '';
            identMap = ''
              postgres root postgres
              concourse-map ${username} ${username}
            '';
            initialScript = pkgs.writeText "init-sql-script" ''
              alter user ${username} with password '${password}';
            '';
          };
        };
      };
  };

  testScript = ''
    start_all()

    # Ensure the services are running and not dead
    server.wait_for_unit("concourse-web")
  '';
}
