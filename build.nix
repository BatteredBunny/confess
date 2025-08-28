{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-Bb65qeXEvQGJ2flzL3Owqo3IWLJW5nLz8drOb+zLaQ0=";

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
