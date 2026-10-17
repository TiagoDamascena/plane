{
  description = "Plane (plane.so) packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      # Plane only publishes an x86_64 AppImage for Linux.
      systems = [ "x86_64-linux" ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _prev: {
        plane-desktop = final.callPackage ./pkgs/plane-desktop/package.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        plane-desktop = pkgs.callPackage ./pkgs/plane-desktop/package.nix { };
        update-plane-desktop = pkgs.callPackage ./pkgs/plane-desktop/update.nix { };
        default = plane-desktop;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.plane-desktop;
        };
        update = {
          type = "app";
          program = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.update-plane-desktop;
        };
      });

      checks = forAllSystems (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) plane-desktop;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
