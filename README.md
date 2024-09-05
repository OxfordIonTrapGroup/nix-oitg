Nix flakes for the Oxford Ion Trap Quantum Computing group
==========================================================

This repository contains derivations for deploying ARTIQ via the
Nix package manager.

To use, first set up Nix as described on its [website][nix]. Make
sure you have version 2.4 or higher (tested: 2.6–2.24). Both single-user
and multi-user installs work fine for our purposes. If you choose
the latter, you will probably want to add your user to the trusted
users to be able to mark the binary caches as trusted (see below).

Then, to set up an environment suitable for running `artiq_master`
and related processes, clone this repository, e.g. into your
scratch folder:

```
$ cd ~/scratch
$ git clone https://github.com/OxfordIonTrapGroup/nix-oitg.git
```

Now, just run ``nix develop`` and follow the instructions on screen:
```
$ nix develop ~/scratch/nix-oitg
```


Binary caches/substituters
--------------------------

The Nix flake, together with its dependencies, provides a complete
set of instructions on how to build all the components necessary to
run ARTIQ from scratch (i.e., the respective source code). This,
however, is quite a slow process, as it includes big projects such
as LLVM, Rust, Python, etc. As building everything from source every
time clearly isn't necessary, Nix allows one to configure
"substituters", servers that can provide pre-built binary packages
to be downloaded and extracted in place of re-running the build
process locally on each machine.

This flake configure two extra substituters: First, our local build
server (10.255.6.197) for custom packages and fast installs, and,
as a fallback, the M-Labs build server. While we have some
customisations to ARTIQ itself, the latter is still useful for
things like Rust and LLVM, even though in normal use, those binaries
should also be cached by our build server.

The former is accessed via SSH through a special, locked-down
`nix-ssh` user. Authentication should already be set up on the
group network, but note that Nix rejects connection to hosts the
SSH host keys of which are not known, rather than prompting you.
Thus, before running `nix develop`, make sure to connect to the
build server at least once:

    $ ssh nix-ssh@10.255.6.197

If everything works, you should get a
`PTY allocation request failed on channel 0` error message, at which
point you can close the session (e.g. by pressing `Ctrl-C`).

If you are running Nix in multi-user mode, be sure to run this
as the root user instead:

    $ sudo ssh nix-ssh@10.255.6.197


Use outside Oxford
------------------

This flake pulls in several packages that are internal to the
Oxford Ion Trap Quantum Computing group, and hosted on our
private GitLab instance (gitlab.physics.ox.ac.uk). However, at this
stage, none of these contain any modifications necessary to make use
of our open-source projects (e.g. ndscan) in your laboratory. If you
do want to re-use this somewhat idiosyncratic method of deploying
ARTIQ as well, you will need to comment out the Oxford-specific
packages in `flake.nix` and change the URLs for `artiq.git` etc. to
refer to the public upstream repositories instead.


Development notes
-----------------

Please keep the Nix code formatted using `nixfmt`. You can easily
get it from Nix itself, e.g. using `nix shell nixpkgs#nixfmt`.



[nix]: https://nixos.org/download.html
