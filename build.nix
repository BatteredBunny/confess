{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-uI9+uIMDt259cV0RNyYF9nA6ShBa0iBRpsmJ+wD3aXM=";

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
