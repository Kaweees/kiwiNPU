{
  description = "KiwiNPU development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openlane.url = "github:efabless/openlane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, openlane, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = let pkgs = import nixpkgs { inherit system; };
      in pkgs.mkShell {
        buildInputs = [
          pkgs.gnumake # GNU Make
          pkgs.verilator # Verilog simulator
          pkgs.iverilog # Verilog simulator
          pkgs.ncurses # tput (terminal formatting)
          pkgs.findutils # find command
          pkgs.gnugrep # grep
          pkgs.coreutils # basic Unix commands
          pkgs.which # which command
          # From OpenLane flake
          openlane.packages.${system}.openroad
          openlane.packages.${system}.openlane
        ];
      };
    });
}
