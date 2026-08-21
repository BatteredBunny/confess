{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-biRKrsBLnnzjS40RlxMFU5nWMwwWbYLpA8G5rmsdojE=";

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
