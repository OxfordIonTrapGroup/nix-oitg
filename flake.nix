{
  description = "Environment for running ARTIQ master in lab one/HOA2";

  inputs = {
    artiq.url = "git+ssh://git@gitlab.physics.ox.ac.uk/ion-trap/artiq.git";

    # Oxford-flavoured ARTIQ packages. We pull them in as flake inputs so we can
    # conveniently update them using `nix lock`, etc., rather than manually having to
    # track hashes.
    sipyco.url = "github:OxfordIonTrapGroup/sipyco";
    sipyco.inputs.nixpkgs.follows = "artiq/nixpkgs";
    artiq.inputs.sipyco.follows = "sipyco";
    src-andorEmccd = {
      url = "github:dnadlinger/andorEmccd";
      flake = false;
    };
    src-llama = {
      url = "git+ssh://git@gitlab.physics.ox.ac.uk/ion-trap/llama.git";
      flake = false;
    };
    src-ndscan = {
      url = "github:OxfordIonTrapGroup/ndscan";
      flake = false;
    };
    src-oitg = {
      url = "github:OxfordIonTrapGroup/oitg";
      flake = false;
    };
    src-oxart = {
      url = "git+ssh://git@gitlab.physics.ox.ac.uk/ion-trap/oxart.git";
      flake = false;
    };
    src-oxart-devices = {
      url = "github:OxfordIonTrapGroup/oxart-devices";
      flake = false;
    };
  };
  outputs = { self, artiq, sipyco, src-andorEmccd, src-llama
    , src-ndscan, src-oitg, src-oxart, src-oxart-devices }:
    let
      nixpkgs = artiq.nixpkgs;
      andorEmccd = nixpkgs.python3Packages.buildPythonPackage {
        name = "andorEmccd";
        src = src-andorEmccd;
        propagatedBuildInputs = [ nixpkgs.python3Packages.numpy ];
      };
      llama = nixpkgs.python3Packages.buildPythonPackage {
        name = "llama";
        src = src-llama;
        propagatedBuildInputs = [
          nixpkgs.python3Packages.aiohttp
          sipyco.packages.x86_64-linux.sipyco
        ];
      };
      oitg = nixpkgs.python3Packages.buildPythonPackage {
        name = "oitg";
        src = src-oitg;
        propagatedBuildInputs = with nixpkgs.python3Packages; [
          scipy
          statsmodels
        ];
        # Whatever magic `setup.py test` does by default fails for oitg.
        installCheckPhase = ''
          ${nixpkgs.python3.interpreter} -m unittest discover test
        '';
      };
      ndscan = nixpkgs.python3Packages.buildPythonPackage {
        name = "ndscan";
        src = src-ndscan;
        propagatedBuildInputs = [ artiq.packages.x86_64-linux.artiq oitg ];
      };
      oxart = nixpkgs.python3Packages.buildPythonPackage {
        name = "oxart";
        src = src-oxart;
        propagatedBuildInputs = [ artiq.packages.x86_64-linux.artiq oitg ];
        installCheckPhase = ''
          ${nixpkgs.python3.interpreter} -m unittest discover test
        '';
      };
      oxart-devices = nixpkgs.python3Packages.buildPythonPackage {
        name = "oxart-devices";
        src = src-oxart-devices;
        propagatedBuildInputs = [
          nixpkgs.python3Packages.appdirs
          oitg
          sipyco.packages.x86_64-linux.sipyco
        ];
        # Need to manually remove .pyc files conflicting with oxart (both share the
        # oxart.* namespace).
        postFixup = ''
          rm -r $out/${nixpkgs.python3.sitePackages}/oxart/__pycache__
        '';
        # Auto-discovery pulls in some ``test`` modules for manual interactive testing
        # (that also require Windows and/or hardware).
        doCheck = false;
      };
      python-env = (nixpkgs.python3.withPackages (ps:
        (with ps; [ aiohttp influxdb llvmlite numba pyzmq ]) ++ [
          # ARTIQ will pull in a large number of transitive dependencies, most of which
          # we also rely on. Currently, it is a bit overly generous, though, in that it
          # pulls in all the requirements for a full GUI and firmware development
          # install (Qt, Rust, etc.). Could slim down if disk usage ever becomes an
          # issue.
          artiq.packages.x86_64-linux.artiq
          andorEmccd
          llama
          ndscan
          oitg
          oxart
          oxart-devices
        ]));
      artiq-master-dev = nixpkgs.mkShell {
        name = "artiq-master-dev";
        buildInputs = [
          python-env
          artiq.packages.x86_64-linux.openocd-bscanspi
          nixpkgs.julia_17-bin
        ];
        shellHook = ''
          if [ -z "$OITG_SCRATCH_DIR" ]; then
            echo "$(tput setaf 7)OITG_SCRATCH_DIR environment variable not set, defaulting to ~/scratch.$(tput sgr0)"
            export OITG_SCRATCH_DIR=$HOME/scratch
          fi
          ${
            ./src/setup-artiq-master-dev.sh
          } ${python-env} ${python-env.sitePackages} || exit 1
          source $OITG_SCRATCH_DIR/nix-oitg-venvs/artiq-master-dev/bin/activate || exit 1
        '';
      };
    in {
      # Allow explicit use from outside the flake, in case we want to add other targets
      # or build on this in the future.
      inherit artiq-master-dev;
      inherit andorEmccd llama oitg ndscan oxart oxart-devices;

      defaultPackage.x86_64-linux = artiq-master-dev;
    };

  nixConfig = {
    extra-trusted-public-keys =
      "nixbld.m-labs.hk-1:5aSRVA5b320xbNvu30tqxVPXpld73bhtOeH6uAjRyHc=";
    extra-substituters = "https://nixbld.m-labs.hk";
  };
}
