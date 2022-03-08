{
  description = "Environment for running ARTIQ master in lab one/HOA2";

  inputs.artiq.url =
    "git+ssh://git@gitlab.physics.ox.ac.uk/ion-trap/artiq.git?ref=dpn/nix-riscv";
  outputs = { self, artiq }:
    let
      pkgs = artiq.inputs.nixpkgs.legacyPackages.x86_64-linux;
      python-env = (pkgs.python3.withPackages (ps:
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
          migen
          misoc
          qasync
          microscope
        ])));
    in {
      devShell.x86_64-linux = pkgs.mkShell {
        name = "artiq-dev-shell";
        buildInputs = [
          python-env
          pkgs.llvmPackages_11.clang-unwrapped
          pkgs.llvm_11
          pkgs.lld_11
          artiq.packages.x86_64-linux.openocd-bscanspi
        ];
        shellHook = ''
          ./configure.sh ${python-env}/${python-env.sitePackages}
          source ./artiq-env/bin/activate
        '';
      };
    };

  nixConfig = {
    extra-trusted-public-keys =
      "nixbld.m-labs.hk-1:5aSRVA5b320xbNvu30tqxVPXpld73bhtOeH6uAjRyHc=";
    extra-substituters = "https://nixbld.m-labs.hk";
  };
}
