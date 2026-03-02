{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-Fl5LOWSG2OE/p97GUtmg7IF+Im4zQY09v2oW0I4cWwM=";

  ldflags = [
    "-s"
    "-w"
  ];

  preInstall = ''
    mkdir $out
    cp -r static $out/static
  '';

  meta = {
    description = "Confessional website backend";
    homepage = "https://github.com/BatteredBunny/confess";
    mainProgram = "confess";
  };
}
