{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-UpZiwJGtIHHiqpFFU2rSr8iFjxzNommiyvCx+CpxSl4=";

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
