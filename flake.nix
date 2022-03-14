{
  description = "Environment for running ARTIQ master in lab one/HOA2";

  inputs = {
    artiq.url =
      "git+ssh://git@gitlab.physics.ox.ac.uk/ion-trap/artiq.git?ref=dpn/nix-riscv";

    # Julia 1.7 is not available from nixpkgs 21.11; this second copy can be removed
    # once it is.
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, artiq, nixpkgs-unstable }:
    let
      nixpkgs = artiq.inputs.nixpkgs.legacyPackages.x86_64-linux;
      python-env = (nixpkgs.python3.withPackages (ps:
        (with ps; [
          aiohttp
          dateutil
          h5py
          influxdb
          # FIXME: numba, currently causes conflict with llvmlite-new.
          numpy
          paramiko
          prettytable
          python-Levenshtein
          scipy
          pyserial
          pyzmq
        ]) ++ (with artiq.packages.x86_64-linux; [
          llvmlite-new
          misoc  # For flterm.
          qasync
        ])));
      artiq-master-dev = nixpkgs.mkShell {
        name = "artiq-dev-shell";
        buildInputs = [
          python-env
          nixpkgs.llvm_11
          nixpkgs.lld_11
          artiq.packages.x86_64-linux.openocd-bscanspi
          nixpkgs-unstable.legacyPackages.x86_64-linux.julia_17-bin
        ];
        shellHook = ''
          if [ -z "$OITG_SCRATCH_DIR" ]; then
            echo "OITG_SCRATCH_DIR environment variable not set, defaulting to ~/scratch."
            export OITG_SCRATCH_DIR=$HOME/scratch
          fi
          ${./src/setup-artiq-master-dev.sh} ${python-env} ${python-env.sitePackages} || exit 1
          source $OITG_SCRATCH_DIR/venv/artiq-master-dev/bin/activate || exit 1
        '';
      };
    in {
      # Allow explicit use from outside the flake, in case we want to add other targets
      # or build on this in the future.
      inherit artiq-master-dev;

      defaultPackage.x86_64-linux = artiq-master-dev;
    };

  nixConfig = {
    extra-trusted-public-keys =
      "nixbld.m-labs.hk-1:5aSRVA5b320xbNvu30tqxVPXpld73bhtOeH6uAjRyHc=";
    extra-substituters = "https://nixbld.m-labs.hk";
  };
}
