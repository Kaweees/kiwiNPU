{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gnumake # GNU Make
    just # Just
    verilator # Verilog simulator
    iverilog # Verilog simulator
    verible # Verilog formatter and linter
    gtkwave # GTKWave waveform viewer
    openfpgaloader # openFPGALoader
    docker
    xhost # X server
  ];

  # Shell hook to set up environment
  shellHook = ''
    export TMPDIR=/tmp
    just install
  '';
}
