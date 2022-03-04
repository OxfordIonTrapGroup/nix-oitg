#!/bin/bash

BLUE='\033[1;34m'
NO_COLOR='\033[0m'

NIX_PYTHON_PATH=$(which python)
NIX_ENV_PATH="${NIX_PYTHON_PATH%/bin/python}"
NIX_SITE_PKGS="$NIX_ENV_PATH/lib/python3.8/site-packages/"

if [ -d "$(pwd)/artiq-env/" ] ; then
     echo "Using existing artiq-env"
else
    echo "artiq-env not found"
    echo "Creating new artiq-env..."
    python -m venv artiq-env
fi

echo ${NIX_SITE_PKGS} >> $(pwd)/artiq-env/lib/python3.8/site-packages/nix.pth

printf """${BLUE}artiq-env${NO_COLOR} installed to ${BLUE}$(pwd)${NO_COLOR}
To activate, run:
    ${BLUE}source artiq-env/bin/activate${NO_COLOR}
Packages can then be installed with:
    ${BLUE}pip install -e /path/to/pkg/${NO_COLOR}
Deactivate the virtualenv with:
    ${BLUE}deactivate${NO_COLOR}
Exit the nix environment with:
    ${BLUE}exit${NO_COLOR}
"""
