{
  description = "Environment for running ARTIQ master in lab one/HOA2";

  inputs = {
    artiq.url = "git+ssh://git@gitlab.physics.ox.ac.uk/ion-trap/artiq.git";

    # Oxford-flavoured ARTIQ packages. We pull them in as flake inputs so we can
    # conveniently update them using `nix lock`, etc., rather than manually having to
    # track hashes.
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
  outputs = { self, artiq, src-andorEmccd, src-llama, src-ndscan, src-oitg
    , src-oxart, src-oxart-devices }:
    let
      nixpkgs = artiq.nixpkgs;
      sipyco = artiq.inputs.sipyco;
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
        format = "pyproject";
        propagatedBuildInputs = with nixpkgs.python3Packages; [
          h5py
          scipy
          statsmodels
          nixpkgs.python3Packages.poetry-core
          nixpkgs.python3Packages.poetry-dynamic-versioning
        ];
        # Whatever magic `setup.py test` does by default fails for oitg.
        installCheckPhase = ''
          ${nixpkgs.python3.interpreter} -m unittest discover test
        '';
      };
      ndscan = nixpkgs.python3Packages.buildPythonPackage {
        name = "ndscan";
        src = src-ndscan;
        format = "pyproject";
        propagatedBuildInputs = [
          artiq.packages.x86_64-linux.artiq
          oitg
          nixpkgs.python3Packages.poetry-core
          nixpkgs.python3Packages.pyqt6
        ];
        # ndscan depends on pyqtgraph>=0.12.4 to display 2d plot colorbars, but this
        # is not yet in nixpkgs 23.05. Since this flake will mostly be used for
        # server-(master-)side installations, just patch it out for now. In theory,
        # pythonRelaxDepsHook should do this more elegantly, but it does not seem to
        # be run before pipInstallPhase.
        # FIXME: qasync/sipyco/oitg dependencies which explicitly specify a Git source
        # repo do not seem to be matched by the packages pulled in via Nix; what is the
        # correct approach here?
        postPatch = ''
          sed -i -e "s/^pyqtgraph = .*//" pyproject.toml
          sed -i -e "s/^qasync = .*//" pyproject.toml
          sed -i -e "s/^sipyco = .*//" pyproject.toml
          sed -i -e "s/^oitg = .*//" pyproject.toml
        '';
        dontWrapQtApps = true; # Pulled in via the artiq package; we don't care.
      };
      oxart = nixpkgs.python3Packages.buildPythonPackage {
        name = "oxart";
        src = src-oxart;
        propagatedBuildInputs = [ artiq.packages.x86_64-linux.artiq oitg ];
        installCheckPhase = ''
          ${nixpkgs.python3.interpreter} -m unittest discover test
        '';
        dontWrapQtApps = true; # Pulled in via the artiq package; we don't care.
      };
      oxart-devices = nixpkgs.python3Packages.buildPythonPackage {
        name = "oxart-devices";
        src = src-oxart-devices;
        format = "pyproject";
        propagatedBuildInputs = [
          nixpkgs.python3Packages.appdirs
          nixpkgs.python3Packages.influxdb
          nixpkgs.python3Packages.pyserial
          nixpkgs.python3Packages.pyzmq
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
        (with ps; [ aiohttp h5py influxdb llvmlite numba pyzmq ]) ++ [
          # ARTIQ will pull in a large number of transitive dependencies, most of which
          # we also rely on. Currently, it is a bit overly generous, though, in that it
          # pulls in all the requirements for a full GUI and firmware development
          # install (Qt, Rust, etc.). Could slim down if disk usage ever becomes an
          # issue.
          artiq.packages.x86_64-linux.artiq
          artiq.packages.x86_64-linux.entangler
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
          nixpkgs.julia_19-bin
          nixpkgs.lld_14
          nixpkgs.llvm_14
          nixpkgs.libusb-compat-0_1
        ];
        shellHook = ''
          if [ -z "$OITG_SCRATCH_DIR" ]; then
            echo "OITG_SCRATCH_DIR environment variable not set, defaulting to ~/scratch."
            export OITG_SCRATCH_DIR=$HOME/scratch
            export QT_PLUGIN_PATH=${nixpkgs.qt5.qtbase}/${nixpkgs.qt5.qtbase.dev.qtPluginPrefix}
            export QML2_IMPORT_PATH=${nixpkgs.qt5.qtbase}/${nixpkgs.qt5.qtbase.dev.qtQmlPrefix}
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
      "buildsvr-1:3EJ00F+rbqkxwDTforU07Jj1Rzq3B+uVWc70+8fXv/s= nixbld.m-labs.hk-1:5aSRVA5b320xbNvu30tqxVPXpld73bhtOeH6uAjRyHc=";
    extra-substituters = "ssh://nix-ssh@10.255.6.197 https://nixbld.m-labs.hk";
  };
}
