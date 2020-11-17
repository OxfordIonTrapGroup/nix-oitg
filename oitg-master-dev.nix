{ pkgs ? import <nixpkgs> {} }:

let
    dependencies = import ./src/dependencies.nix { inherit pkgs; };
    libartiq-support = (import <artiq-fast> { inherit pkgs; }).libartiq-support;
    set-scratch-dir = ./src/set-scratch-dir.sh;
in pkgs.mkShell {
  buildInputs = [dependencies.artiq-master];
  shellHook = ''
      source ${set-scratch-dir};
      export PYTHONPATH="$scratch_dir/artiq:$scratch_dir/artiq-comtools:$scratch_dir/ndscan:$scratch_dir/oitg:$scratch_dir/oxart:$scratch_dir/sipyco:$PYTHONPATH"
      export LIBARTIQ_SUPPORT=${libartiq-support}/libartiq_support.so
  '';
}
