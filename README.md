Nix scripts for the Oxford Ion Trap Quantum Computing group
===

This respository contains derivations for installing various
Oxford-flavoured ARTIQ packages via the [Nix][nix] package manager.

Thus far, they have been primarily tested on Linux, but should work
macOS with minimal adaptions as well.


Installation
---

These Nix derivations ("packages") build on the upstream ARTIQ Nix
channel maintained by M-Labs. Thus, first follow the [ARTIQ
installation instructions](artiq-install) to switch to the correct
`nixpkgs` release. Then, add the `artiq-fast` channel and update the
configuration:

```
nix-channel --add https://nixbld.m-labs.hk/channel/custom/artiq/fast-beta/artiq-fast
nix-channel --update
```

You will also want to add the M-Labs package cache and their
public key to `~/.config/nix/nix.conf`, which you will likely need
to create, which avoids having to recompile everything from scratch,
greatly speeding up installation. (This assumes you are running Nix
in single-user mode; for multi-user installs, you will have to make
your user trusted in `/etc/nix/nix.conf`, or mark your user as
trusted there.)


Development mode
---

To work on the ARITQ client itself (or our libraries, e.g. ndscan),
it is convenient to pull in all the dependencies from a directory on
disk instead of rebuilding packages all the time, like
`python setup.py develop` or `pip install -e`. For this, you can use
the `oitg-client-dev` derivation:

First, clone all the necessary the repositories into a directory of
your choice. (We tend to use `~/scratch` on lab machines by
convention.) You'll probably want `artiq`, `artiq-comtools`, `ndscan`,
`oitg`, `oxart`, and `sipyco`.

You can then use `nix-shell` to open a shell with all these
directories on the Python path, and (at the time of writing) their
dependencies installed via Nix:
```
$ nix-shell nix-oitg/oitg-client-dev.nix
```
If you didn't clone the repositories into `~/scratch`, set
`OITG_SCRATCH` accordingly.


[nix]: https://nixos.org/
[artiq-install]: https://m-labs.hk/artiq/manual/installing.html
