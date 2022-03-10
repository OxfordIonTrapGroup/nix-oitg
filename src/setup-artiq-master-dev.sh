#!/bin/bash
set -euo pipefail

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

if [[ -z ${1:-} || -z ${2:-} ]]; then
    warn "Expected arguments with Nix python-env path and relative site-packages path."
    diag "This script should be called via the Nix flake only."
    exit 1
fi
nix_python_root=$1
nix_site_pkgs_subdir=$2

venv_root="${OITG_SCRATCH_DIR}/venv"
mkdir -p "${venv_root}"
venv_path="${venv_root}/artiq-master-dev"
if [[ -d "${venv_path}" ]]; then
    diag "Using existing venv: ${venv_path}."
else
    diag "Creating new venv: ${venv_path}."
    python -m venv "${venv_path}"
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

printf """${blue}artiq-master-dev${reset} installed to ${blue}$(pwd)${reset}
To activate, run:
    ${blue}source artiq-master-dev/bin/activate${reset}
Packages can then be installed with:
    ${blue}pip install -e /path/to/pkg/${reset}
Deactivate the virtualenv with:
    ${blue}deactivate${reset}
Exit the nix environment with ${blue}exit${reset} or ${blue}Ctrl+D${reset}.
"""