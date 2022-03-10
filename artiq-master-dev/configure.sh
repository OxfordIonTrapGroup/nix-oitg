#!/bin/bash
set -euo pipefail

warn=$(tput setaf 172)$(tput bold)
blue=$(tput setaf 4)
reset=$(tput sgr0)

if [ -z "$1" ]; then
    echo "Expected argument with Nix python-env path."
    echo "${warn}This script should be called via the Nix flake only${reset}."
    exit 1
fi
nix_site_pkgs=$1

venv_root="${OITG_SCRATCH_DIR}/venv"
mkdir -p "${venv_root}"
venv_path="${venv_root}/artiq-master-dev"
if [ -d ${venv_path} ]; then
    echo "Using existing venv: ${venv_path}"
else
    echo "Creating new venv: ${venv_path}"
    python -m venv "${venv_path}"
fi

# Always update the .pth file we use for the venv to be able to find packages
# provided via Nix to make sure it continues to reference the right set of
# packages if the definition in the flake (or the Python version, etc.) is
# updated.
venv_site_packages=(${venv_path}/lib/python3*/site-packages)
echo ${nix_site_pkgs} > ${venv_site_packages}/nix.pth

printf """${blue}artiq-master-dev${reset} installed to ${blue}$(pwd)${reset}
To activate, run:
    ${blue}source artiq-master-dev/bin/activate${reset}
Packages can then be installed with:
    ${blue}pip install -e /path/to/pkg/${reset}
Deactivate the virtualenv with:
    ${blue}deactivate${reset}
Exit the nix environment with ${blue}exit${reset} or ${blue}Ctrl+D${reset}.
"""
