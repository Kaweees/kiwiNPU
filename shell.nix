{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake # GNU Make
    pkgs.verilator # Verilog simulator
    pkgs.iverilog # Verilog simulator
    pkgs.verible # Verilog formatter and linter
    pkgs.gtkwave # GTKWave waveform viewer
    pkgs.nodePackages.wavedrom-cli # Convert VCD files to Wavedrom format
    pkgs.openfpgaloader # openFPGALoader
  ];

  # Shell hook to set up environment
  shellHook = "";
}
