# Cheeky script to read $scratch_dir from OITG_SCRATCH with a default while
# not triggering Nix's experssion expansion. I'm sure there is a better way
# of doing this.
scratch_dir="${OITG_SCRATCH:-$HOME/scratch}"
