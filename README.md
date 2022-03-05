Nix flakes for the Oxford Ion Trap Quantum Computing group
==========================================================

This respository contains derivations for deploying ARTIQ via the
Nix package manager.

To use, first set up Nix as described on its [website](nix). Make
sure you have version 2.4 or higher (tested: 2.6). Both single-user
and multi-user installs work fine for our purposes. If you choose
the latter, you will probably want to add your user to the trusted
users to be able to add the M-Labs binary caches.

Then, to set up an ARTIQ master environment, clone this repostiory,
e.g. into you scratch folder:

```
$ cd ~/scratch
$ git clone https://github.com/OxfordIonTrapGroup/nix-oitg.git
```

Now, just run ``nix develop`` and follow the instructions on screen:
```
$ nix develop ~/scratch/nix-oitg/artiq-master-dev
```

You will probably want to allow use of the M-Labs binary caches
("substituters") to avoid local rebuilding of packages, which
takes a while.


Development notes
-----------------

Please keep the Nix code formatted using `nixfmt`. You can easily
get it from Nix itself, e.g. using `nix shell nixpkgs#nixfmt`.



[nix]: https://nixos.org/download.html
