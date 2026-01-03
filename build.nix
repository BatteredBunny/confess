{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-vcC0maJhtRsEN4OLZPIEnJThNxaGwm7ueRAQY3hsoVU=";

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
