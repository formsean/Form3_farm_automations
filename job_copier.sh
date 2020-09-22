#!/bin/bash
# Author: Robert Gambee
# Date: 2019-10-29

USAGE="Copy the most recently-uploaded job from one printer to another.

Usage: job_copier.sh source_IP destination_IP

There are two required arguments: the IP addresses of the source and
destination printers, respectively. On Mac, it may be possible to use
the printer's hostname (PrinterSerial.local) instead of its IP address.

Examples:
    job_copier.sh 10.0.0.1 10.0.0.2
    job_copier.sh ShimmeringSource.local DashingDestination.local
"

if [[ $# != 2 ]]
then
    echo "$USAGE"
    exit 0
fi

SOURCE="$1"
DESINATION="$2"

# First confirm that we can connect to both the source and destination printers
for IP in "$SOURCE" "$DESINATION"
do
    echo "Attempting to connect to $IP"
    ssh -T -o "ConnectTimeout=5" "root@$IP" exit
    if [[ $? != 0 ]]
    then
        echo "Could not connect to $IP"
        exit 1
    fi
    echo "Success"
done

set -e

# Find most recent job on source printer
echo "Finding most recently uploaded job on $SOURCE"
SOURCE_JOB="$(ssh "root@$SOURCE" ls -rt1d "/data/jobs/{*[1-9a-f]*}" | tail -1)"
if [[ -z "$SOURCE_JOB" ]]
then
    echo "Unable to find job on source printer"
    exit 2
fi
# Add trailing slash so rsync doesn't create extra directory on destination
SOURCE_JOB="$SOURCE_JOB/"
JOB_NAME="$(ssh "root@$SOURCE" jq .Name "$SOURCE_JOB/Job.json")"
NUM_FILES_SOURCE=$(ssh "root@$SOURCE" ls "$SOURCE_JOB" | wc -l | tr -d '[:space:]')

echo "Copying job named $JOB_NAME from $SOURCE to $DESINATION"
RSYNC_COMMAND="rsync -ai --exclude=Prints --rsh 'ssh -o StrictHostKeyChecking=no' \"$SOURCE_JOB\" \"root@$DESINATION:$SOURCE_JOB\""

ssh "root@$SOURCE" "$RSYNC_COMMAND" # | pv -lept -i 0.1 -s "$NUM_FILES_SOURCE" > /dev/null
# Restart Formule on destination printer so job appears on UI

ssh "root@$DESINATION" "/etc/init.d/formule restart" > /dev/null
echo "Done!"
