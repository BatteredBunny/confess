{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      systems = lib.systems.flakeExposed;

      forAllSystems = lib.genAttrs systems;

      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
        }
      );
    in
    {
      overlays.default = final: prev: {
        confess = self.packages.${final.stdenv.system}.confess;
      };

      nixosModules.default = import ./module.nix;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              go
              sqlite
            ];
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        rec {
          confess = default;
          default = pkgs.callPackage ./build.nix { };

          # nix run .#test-service.driverInteractive
          test-service = pkgs.callPackage ./test.nix {
            inherit self;
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          test-service = pkgs.callPackage ./test.nix {
            inherit self;
          };
        }
      );
    };
}
