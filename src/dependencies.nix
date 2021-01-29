# Contains lists of dependencies for various common configurations.
#
# Client refers to only ARITQ client tools (dashboard, RPC tool, etc., but not master),
# Master to a complete ARTIQ master installation including the core device kernel
# toolchain, tools for flashing FPGAs, etc. (but not building gateware).
# 
# The `artiq-*` names refer to only non-Oxford dependencies, whereas `oitg-*` also
# includes our own libraries (for being able to install the latter in dev mode).

{ pkgs }:

let
  artiq-fast = import <artiq-fast> { inherit pkgs; };
  # qasync not exported from nix-scripts@58aabaa.
  afppd = import <artiq-fast/pkgs/python-deps.nix> {
    inherit (pkgs) stdenv fetchFromGitHub python3Packages fetchgit;
    misoc-new = true;
  };
in rec {
  artiq-client = [
    (pkgs.python3.withPackages (ps:
      (with ps; [
        dateutil
        h5py
        numpy
        numba
        paramiko
        prettytable
        python-Levenshtein
        scipy
        sphinx
        sphinx_rtd_theme
        pyzmq
      ]) ++ (with artiq-fast; [ pyqtgraph-qt5 pythonparser ])
      ++ [ afppd.qasync ]))
    pkgs.zeromq
  ];
  artiq-master = [
    (pkgs.python3.withPackages (ps:
      (with ps; [
        dateutil
        h5py
        numpy
        numba
        paramiko
        prettytable
        python-Levenshtein
        scipy
        pyzmq
      ]) ++ (with artiq-fast; [ lit llvmlite-artiq pythonparser ])
      ++ [ afppd.qasync ]))
    (with artiq-fast; [
      cargo
      rustc
      binutils-or1k
      binutils-arm
      llvm-or1k
      outputcheck
    ])
    pkgs.gnumake
    pkgs.zeromq
  ];
}
