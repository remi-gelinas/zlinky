{
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" ];

      perSystem =
        {
          lib,
          inputs',
          system,
          config,
          ...
        }:
        let
          zig-env = inputs.zig2nix.zig-env.${system} { zig = inputs'.zig2nix.packages.zig.master.bin; };
          system-triple = zig-env.lib.zigTripleFromString system;
        in
        {
          packages.zlinky = config.legacyPackages.zlinky.${system-triple}.override {
            zigPreferMusl = false;
            zigDisableWrap = false;
          };

          legacyPackages.zlinky = lib.genAttrs zig-env.lib.allTargetTriples (
            target:
            zig-env.packageForTarget target {
              src = lib.cleanSource ./.;

              zigPreferMusl = true;
              zigDisableWrap = true;
            }
          );

          apps.lock-dependencies = zig-env.app [ zig-env.zon2json-lock ] "zon2json-lock build.zig.zon";
          devShells.default = zig-env.mkShell { name = "zlinky-dev"; };
        };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig2nix.url = "github:Cloudef/zig2nix";
    zig2nix.inputs.nixpkgs.follows = "nixpkgs";
  };
}
