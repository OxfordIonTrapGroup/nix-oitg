#!/bin/bash

WARN=$(tput setaf 172)$(tput bold)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

if [ -z "$1" ]; then
    echo "Expected argument with Nix python-env path."
    echo "${WARN}This script should be called via the Nix flake only${RESET}."
    exit 1
fi
NIX_SITE_PKGS=$1

venv_path = "$(pwd)/artiq-master-dev/"
if [ -d venv_path ]; then
    echo "Using existing venv: ${venv_path}"
else
    echo "Creating new venv: ${venv_path}"
    python -m venv ${venv_path}
fi

echo ${NIX_SITE_PKGS} >> ${venv_path}/lib/*/site-packages/nix.pth

printf """${BLUE}artiq-master-dev${RESET} installed to ${BLUE}$(pwd)${RESET}
To activate, run:
    ${BLUE}source artiq-master-dev/bin/activate${RESET}
Packages can then be installed with:
    ${BLUE}pip install -e /path/to/pkg/${RESET}
Deactivate the virtualenv with:
    ${BLUE}deactivate${RESET}
Exit the nix environment with:
    ${BLUE}exit${RESET}
"""
