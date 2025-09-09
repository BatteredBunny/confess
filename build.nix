{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-eeQQKv7oGnxSud5uZjjYQ5pQids8TKx6c+2ojoaZgqQ=";

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
