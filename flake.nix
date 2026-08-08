{
  description = "My ASIC project using LibreLane";

  nixConfig = {
    extra-substituters = "https://nix-cache.fossi-foundation.org";
    extra-trusted-public-keys = "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    librelane.url = "github:librelane/librelane";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      librelane,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ll = librelane.packages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "my-asic-project";

          packages = [
            pkgs.python312
            ll.librelane
            pkgs.gnumake
            pkgs.just
            pkgs.verilator
            pkgs.iverilog
            pkgs.gtkwave
            pkgs.openfpgaloader
            pkgs.docker
            pkgs.xhost
            pkgs.git
          ]
          ++ pkgs.lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) pkgs.verible;

          shellHook = ''
            export TMPDIR=/tmp
            unset PYTHONPATH
            export PDK_ROOT="''${PDK_ROOT:-$HOME/.ciel}"
            echo "LibreLane ready — PDK_ROOT=$PDK_ROOT"
          '';
        };
      }
    );
}
