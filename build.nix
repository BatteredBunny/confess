{ buildGoModule }:
buildGoModule {
  src = ./.;

  name = "confess";
  vendorHash = "sha256-+NkrrJcNj2H2Sk61QdPaydGPx7KiUXVJChGAvsx01Es=";

  ldflags = [
    "-s"
    "-w"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 "$GOPATH/bin/confess" -T $out/bin/confess

    cp -r static $out/static

    runHook postInstall
  '';

  meta = {
    description = "A simple confessional website";
    homepage = "https://forge.catnip.ee/batteredbunny/confess";
    mainProgram = "confess";
  };
}
