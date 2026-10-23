{ buildGoLatestModule }:
buildGoLatestModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-PSThEJhrZ8DTxZu6+C+SBLZHUaOxKsZrGc05pgtTG5Y=";

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
