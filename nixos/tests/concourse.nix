{
  config,
  lib,
  pkgs,
  ...
}:
let
  concoursePackage = pkgs.concourse;
  username = "concourse";
in
{
  name = concoursePackage.pname;
  meta.maintainers = [
    # FIXME: Add maintainers
  ];

  nodes = {
    server =
      { config, pkgs, ... }:
      {
        virtualisation.memorySize = 2047;
        services = {
          openssh.enable = true;
          concourse-web = {
            enable = true;
            environment = {
            };
          };
          postgresql = {
            enable = true;
            authentication = ''
              # type database db-user auth-method map
              local ${username} ${username} ident map=concourse-map
            '';
            identMap = ''
              postgres root postgres
              concourse-map ${username} ${username}
            '';
          };
        };
      };
  };

  testScript = ''
    start_all()
  '';
}
