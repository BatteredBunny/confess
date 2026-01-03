{ self, testers }:
testers.nixosTest {
  name = "confess";

  interactive.nodes.machine = {
    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 8888;
        guest.port = 8888;
      }
    ];
  };

  nodes.machine =
    { ... }:
    {
      imports = [
        self.nixosModules.default
      ];

      nixpkgs.overlays = [
        self.overlays.default
      ];

      services.confess-web = {
        enable = true;
        port = 8888;
      };
    };

  testScript =
    { nodes, ... }:
    let
      port = toString nodes.machine.services.confess-web.port;
    in
    ''
      start_all()
      machine.wait_for_unit("confess-web.service")
      machine.wait_for_open_port(${port})
      machine.succeed("curl -f http://localhost:${port}/")
    '';
}