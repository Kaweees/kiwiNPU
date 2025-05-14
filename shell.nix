{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake # GNU Make
    pkgs.verilator # Verilog simulator
    pkgs.iverilog # Verilog simulator
    pkgs.ncurses # tput (terminal formatting)
    pkgs.findutils # find command
    pkgs.gnugrep # grep
    pkgs.coreutils # basic Unix commands
    pkgs.which # which command
    # Uncomment if you need OpenLane/OpenROAD
    pkgs.openroad # OpenROAD
    pkgs.openlane # OpenLane flow
  ];

  # Shell hook to set up environment
  shellHook = "";
}
