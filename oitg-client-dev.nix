{ pkgs ? import <nixpkgs> {} }:

let
    dependencies = import ./src/dependencies.nix { inherit pkgs; };
    set-scratch-dir = ./src/set-scratch-dir.sh;
in pkgs.mkShell {
  # Need extra Qt5 dependency to avoid
  #    qt.qpa.plugin: Could not find the Qt platform plugin "xcb" in ""
  # error when starting dashboard. Quite possibly not everything `full` is necessary,
  # but figuring out the necessary subset would have been a bit laborious and possibly
  # not quite portable.
  buildInputs = [dependencies.artiq-client pkgs.qt5.full];
  shellHook = ''
      source ${set-scratch-dir};
      export PYTHONPATH="$scratch_dir/artiq:$scratch_dir/artiq-comtools:$scratch_dir/ndscan:
        $PYTHONPATH:$scratch_dir/oitg:$scratch_dir/oxart:$scratch_dir/sipyco"
  '';
}
