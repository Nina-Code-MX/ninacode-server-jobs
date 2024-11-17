#!/bin/bash

# Clean Up Dumps Script
# soporte@ninacode.mx
# version 1.0.0

# Die Function
die () {
        printf >&2 "ERROR!\n""$@""\n\t./$0 \nExiting...\n"
        exit 1
}

logger () {
        printf >&2 $(date +"%Y%m%dT%H%M%S")"\t[cleanUp]""$@""\n"
}

logger "Initializing..."

# Parse Arguments
home_path="./"
dump_path="$home_path""/dump"

logger "Cleaning up files older than 8 days"

find $dump_path -type f -ctime +8 -exec rm -f {} \;

logger "Finished"

exit 0;