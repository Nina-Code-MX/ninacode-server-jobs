#!/bin/bash

# Backup Database Script
# soporte@ninacode.mx
# version 2.0.0

# Die Function
die () {
        printf >&2 "ERROR!\n""$@""\n\t./$0 db_name hourly|daily|weekly\nExiting...\n"
        exit 1
}

logger () {
        printf >&2 $(date +"%Y%m%dT%H%M%S")"\t[backupDB]""$@""\n"
}

logger "Initializing..."

[ "$#" -eq 2 ] || die "2 arguments required, $# provided."

# Parse Arguments
target=$1
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

# Validate Target
mycnf="${home_path}""/confs/.""${target}"".cnf"

if [ ! -f "$mycnf" ]; then
	die "Config file does not exits for ${target}"
fi

filename="${backup_path}/${target}${time}.sql.gz"

logger "["$frequency"]["$target"] Start Dump..."
mysqldump --defaults-file=${mycnf} --no-autocommit --disable-keys --force --single-transaction --skip-extended-insert --hex-blob ${target} | gzip > ${filename}
logger "["$frequency"]["$target"] End Dump..."

logger "["$frequency"]["$target"] Finished"

exit 0;