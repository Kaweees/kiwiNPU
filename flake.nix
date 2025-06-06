{
  description = "KiwiNPU development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openlane.url = "github:efabless/openlane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, openlane, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = let
        pkgs = import nixpkgs { inherit system; };
        openlanePkgs = [ openlane.packages.${system}.default ];
      in pkgs.mkShell {
        buildInputs = [
          pkgs.shellcheck # Shell script linter
          pkgs.gnumake # GNU Make
          pkgs.uv # Python package manager
          pkgs.verilator # Verilog simulator
          pkgs.iverilog # Verilog simulator
          pkgs.verible # Verilog formatter and linter
          pkgs.ncurses # tput (terminal formatting)
          pkgs.findutils # find command
          pkgs.gnugrep # grep
          pkgs.coreutils # basic Unix commands
          pkgs.which # which command
        ] ++ openlanePkgs;

        # Configure OpenLane binary cache
        NIX_CONFIG = ''
          extra-substituters = https://openlane.cachix.org
          extra-trusted-public-keys = openlane.cachix.org-1:5DQ/gq/MbSNCM1ggO4vJ5HdYm2n8iJYKVHjQXHxG/IY=
        '';
      };
    });
}
