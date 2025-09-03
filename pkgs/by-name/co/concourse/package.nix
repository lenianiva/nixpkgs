{
  stdenv,
  lib,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "concourse";
  version = "7.14.1";

  src = fetchTarball {
    url = "https://github.com/concourse/concourse/releases/download/v${version}/concourse-${version}-linux-amd64.tgz";
    sha256 = "5228ecd88c491c814db023c72bf9c5c38b9a0b99d2dba90d84eba34e55e2bac9";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    cp -r $src/bin $out/bin
    cp -r $src/fly-assets $out/fly-assets
    cp -r $src/resource-types $out/resource-types
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://concourse-ci.org/";
    description = "Concourse is an open-source continuous thing-doer.";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
