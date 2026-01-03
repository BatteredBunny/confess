{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-8/T7DSgCXJ4HMM7A+2xg8CAPrZXEAVuYAUewS+tXJVQ=";

  ldflags = [
    "-s"
    "-w"
  ];

  preInstall = ''
    mkdir $out
    cp -r static $out/static
  '';
  meta = {
    description = "A simple confessional website";
    homepage = "https://github.com/BatteredBunny/confess";
    mainProgram = "confess";
  };
}
