#!/bin/bash

# Backup Source Script
# soporte@ninacode.mx
# version 1.0.0

# Die Function
die () {
        printf >&2 "ERROR!\n""$@""\n\t./$0 folder hourly|daily|weekly\nExiting...\n"
        exit 1
}

logger () {
        printf >&2 $(date +"%Y%m%dT%H%M%S")"\t[backupSRC]""$@""\n"
}

logger "Initializing..."

[ "$#" -eq 2 ] || die "2 arguments required, $# provided."

# Parse Arguments
src=$1
frequency=$2
home_path="./"
backup_path="$home_path""/dump"

# Validate Frequency
if [ ! "$frequency" = "hourly" ] &&
        [ ! "$frequency" = "daily" ] &&
        [ ! "$frequency" = "weekly" ]; then
        die "Argument for frequency not valid"
fi

logger "Frequency validated to: "${frequency}

# Time Variable
case $frequency in
        hourly)
                time="-h-"$(date +"%Y%m%dT%H%M00")
                ;;
        daily)
                time="-d-"$(date +"%Y%m%dT000000")
                ;;
        weekly)
                time="-w-"$(date +"%Y%m%dT000000")
                ;;
        *)
                time="-unknown-"$(date +"%Y%m%dT%H%i%s")
                ;;
esac

logger "Time Set"

# Validate Source

if [ ! -d "$src" ]; then
	die "The source directory ${src} does not exists."
fi

target=`basename ${src}`
target="${backup_path}/${target}${time}.tar.gz"

sudo tar -czf $target $src
sudo chown ec2-user:ec2-user $target

ls -l $target

logger "Finished"

exit 0;