#!/bin/bash
set -euo pipefail

warn=$(tput setaf 1)$(tput bold)
grey=$(tput setaf 7)
blue=$(tput setaf 4)
reset=$(tput sgr0)

if [[ -z ${1:-} || -z ${2:-} ]]; then
    echo "${warn}Expected arguments with Nix python-env path and relative site-packages path.${reset}"
    echo "${grey}This script should be called via the Nix flake only.${reset}"
    exit 1
fi
nix_python_root=$1
nix_site_pkgs_subdir=$2

venv_root="${OITG_SCRATCH_DIR}/venv"
mkdir -p "${venv_root}"
venv_path="${venv_root}/artiq-master-dev"
if [ -d ${venv_path} ]; then
    echo "Using existing venv: ${venv_path}."
else
    echo "Creating new venv: ${venv_path}."
    python -m venv "${venv_path}"
fi

# Always update the .pth file we use for the venv to be able to find packages
# provided via Nix to make sure it continues to reference the right set of
# packages if the definition in the flake (or the Python version, etc.) is
# updated.
venv_site_packages="${venv_path}/${nix_site_pkgs_subdir}"
if [ ! -d ${venv_site_packages} ]; then
    echo "${warn}venv site-packages directory not found in expected path,"
    echo "'${venv_site_packages}'.${reset}"
    echo "${grey}If the Python version was updated in the Nix flake, remove the venv directory"
    echo "and re-enter the Nix shell to re-create it, then re-install the necessary"
    echo "packages.${reset}"
    exit 2
fi
echo "${nix_python_root}/${nix_site_pkgs_subdir}" > ${venv_site_packages}/nix.pth

printf """${blue}artiq-master-dev${reset} installed to ${blue}$(pwd)${reset}
To activate, run:
    ${blue}source artiq-master-dev/bin/activate${reset}
Packages can then be installed with:
    ${blue}pip install -e /path/to/pkg/${reset}
Deactivate the virtualenv with:
    ${blue}deactivate${reset}
Exit the nix environment with ${blue}exit${reset} or ${blue}Ctrl+D${reset}.
"""
