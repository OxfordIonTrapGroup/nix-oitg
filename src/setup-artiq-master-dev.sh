#!/bin/bash
set -euo pipefail

# Coloured console output.
warning=$(tput setaf 1)$(tput bold)
grey=$(tput setaf 7)
blue=$(tput setaf 4)
reset=$(tput sgr0)

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
else
    echo "Creating new Python venv: ${venv_path}."
    read -n 1 -p "Continue? [Y/n] " reply
    if [ "$reply" != "" ]; then echo; fi  # Line break
    if [ "$reply" = "${reply#[Nn]}" ]; then
        mkdir -p "${venv_root}"
        python -m venv "${venv_path}"

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
echo "Exit the Nix shell with ${blue}exit${reset} or ${blue}Ctrl+D${reset}."
