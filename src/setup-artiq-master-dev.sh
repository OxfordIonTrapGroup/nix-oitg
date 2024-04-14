#!/bin/bash
set -euo pipefail

# Coloured console output (when not running with $TERM empty or set to a "dumb"
# terminal, as is the case e.g. from systemd units or BuildBot).
if ! tput bold >/dev/null 2>/dev/null; then
    warning=""
    grey=""
    blue=""
    reset=""
else
    warning=$(tput setaf 1)$(tput bold)
    grey=$(tput setaf 7)
    blue=$(tput setaf 4)
    reset=$(tput sgr0)
fi

function warn()
{
    echo "${warning}$1${reset}"
}

function diag()
{
    echo "${grey}$1${reset}"
}

# Parse parameters.
if [[ -z ${1:-} || -z ${2:-} ]]; then
    warn "Expected arguments with Nix python-env path and relative site-packages path."
    diag "This script should be called via the Nix flake only."
    exit 1
fi
nix_python_root=$1
nix_site_pkgs_subdir=$2

# Create/activate venv.
venv_root="${OITG_SCRATCH_DIR}/nix-oitg-venvs"
venv_name="artiq-master-dev"
venv_path="${venv_root}/${venv_name}"
if [[ -d "${venv_path}" ]]; then
    diag "Using existing Python venv: ${venv_path}."

    # Make sure the venv is using the correct Python interpreter. Broken symlinks (such
    # as ones referring to a since-GC'd /nix/store path) trip up the venv code, so
    # remove them first.
    if [[ ! -z $(find "${venv_path}/bin" -type l -xtype l) ]]; then
        diag "Regenerating broken Python executable symlinks."
        find "${venv_path}/bin" -type l -xtype l -delete
    fi
    python -m venv --upgrade "${venv_path}"
else
    echo "Creating new Python venv: ${venv_path}."
    read -n 1 -p "Continue? [Y/n] " reply
    if [ "$reply" = "${reply#[Nn]}" ]; then
        mkdir -p "${venv_root}"
        python -m venv "${venv_path}"
        printf """
Created nested Python virtual environment (venv). ARTIQ itself and commonly
used packages such as ${blue}ndscan${reset}, ${blue}oitg${reset} and ${blue}oxart${reset} are already installed via Nix,
but additional packages not distributed via Nix can be installed using ${blue}pip${reset}
as usual.

This can be particularly useful to install packages in development mode while
actively working on code (e.g. in oxart). For instance, after cloning the
oxart repository to ~/scratch/oxart, installing it in development mode using
    ${blue}pip install pip install --config-settings editable_mode=compat -e ~/scratch/oxart${reset}
will take precedence over the Nix-provided version inside this environment,
such that changes to the code in ~/scratch/oxart immediately take effect.
(The ${grey}--config-settings editable_mode=compat${reset} argument is necessary
for the installation to take precedence over the Nix-provided packages with
recent versions of setuptools.)

The venv should always be used in conjunction with the Nix development shell
(${blue}nix develop${reset}), which in fact automatically activates the venv. Do not manually
activate the venv outside of Nix, nor deactivate the venv while in the Nix shell.

The venv directory ${blue}${venv_path}${reset} is not
managed by Nix and persists across ${blue}nix develop${reset} invocations. To revert all
libraries to the versions specified in the ${blue}nix-oitg${reset} flake (and remove any
additionally installed libraries), simply delete the directory; it will be
re-created on the next ${blue}nix develop${reset} run.

"""
    else
        warn "Python venv not created; set OITG_SCRATCH_DIR environment variable to target path."
        exit 2
    fi
fi

# Always update the .pth file we use for the venv to be able to find packages
# provided via Nix to make sure it continues to reference the right set of
# packages if the definition in the flake (or the Python version, etc.) is
# updated.
venv_site_packages="${venv_path}/${nix_site_pkgs_subdir}"
if [[ ! -d ${venv_site_packages} ]]; then
    warn "venv site-packages directory not found in expected path,"
    warn "'${venv_site_packages}'."
    diag "If the Python version was updated in the Nix flake, remove the venv directory"
    diag "and re-enter the Nix shell to re-create it, then re-install the necessary"
    diag "packages."
    exit 2
fi
echo "${nix_python_root}/${nix_site_pkgs_subdir}" > ${venv_site_packages}/nix.pth

echo "Activated nix-oitg Nix environment with nested Python venv ${blue}${venv_name}${reset}."
echo "To exit the Nix shell, use ${blue}exit${reset} or ${blue}Ctrl+D${reset}."
