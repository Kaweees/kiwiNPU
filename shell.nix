{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake # GNU Make
    pkgs.just # Just
    pkgs.verilator # Verilog simulator
    pkgs.iverilog # Verilog simulator
    pkgs.verible # Verilog formatter and linter
    pkgs.gtkwave # GTKWave waveform viewer
    pkgs.openfpgaloader # openFPGALoader
    pkgs.docker
    pkgs.xhost # X server
  ];

  # Shell hook to set up environment
  shellHook = ''
    export TMPDIR=/tmp
    just install
  '';
}
