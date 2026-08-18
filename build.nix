{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-1eyMsrikp0t3wd1QOHUfoEHbc8UNWyjVAdLRJukoM4A=";

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
