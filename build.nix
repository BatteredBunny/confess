{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-YUWMByZWnOfbRnlr2+D2cOkBjFPuswP4DMg4ZmUrMfo=";

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
