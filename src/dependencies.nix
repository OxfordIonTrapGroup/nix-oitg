# Contains lists of dependencies for various common configurations.
#
# Client refers to only ARITQ client tools (dashboard, RPC tool, etc., but not master),
# Full to a complete ARITQ master installation including the core device kernel
# toolchain, tools for flashing FPGAs, etc.
# 
# The `artiq-*` names refer to only non-Oxford dependencies, whereas `oitg-*` also
# includes our own libraries (for being able to install the latter in dev mode).

{ pkgs }:

let artiq-fast = import <artiq-fast> { inherit pkgs; };
in rec {
  artiq-client = [
    (pkgs.python3.withPackages (ps:
      (with ps; [
        dateutil
        h5py
        numpy
        numba
        paramiko
        python-Levenshtein
        quamash
        scipy
        pyzmq
      ]) ++ (with artiq-fast; [ pyqtgraph-qt5 pythonparser ])))
    pkgs.zeromq
  ];
}
