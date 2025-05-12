{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake # GNU Make
    pkgs.verilator # Verilog simulator
    pkgs.iverilog # Verilog simulator
    # pkgs.tput # GTKWave waveform viewer
  ];

  # Shell hook to set up environment
  shellHook = "";
}
