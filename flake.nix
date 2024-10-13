{
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" ];

      imports = [ inputs.git-hooks-nix.flakeModule ];

      perSystem =
        {
          pkgs,
          inputs',
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;

            overlays = [
              (_: prev: {
                cleanZlinkySource =
                  src:
                  prev.lib.sourceByRegex
                    (prev.lib.cleanSourceWith {
                      inherit src;
                      filter = prev.lib.cleanSourceFilter;
                    })

                    # Only include relevant files in package source
                    [
                      "^build.zig$"
                      "^build.zig.zon$"
                      "^src/.*\.zig$"
                      "^build.zig.zon.nix$"
                    ];
              })
            ];
          };

          packages = {
            zlinky = pkgs.stdenv.mkDerivation {
              pname = "zlinky";
              version = "0.0.0";
              src = pkgs.cleanZlinkySource ./.;

              nativeBuildInputs = [ pkgs.zig.hook ];

              postPatch = ''
                ln -s ${pkgs.callPackage ./build.zig.zon.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
              '';
            };

            # Regenerate build.zig.zon.nix after dependencies changes
            lock-dependencies = pkgs.writeShellApplication {
              name = "lock-dependencies";
              runtimeInputs = [ pkgs.zon2nix ];
              text = "zon2nix > build.zig.zon.nix";
            };
          };

          devShells.default = pkgs.mkShell { packages = [ inputs'.zig.packages.master ]; };
        };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig.url = "github:mitchellh/zig-overlay";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };
}
