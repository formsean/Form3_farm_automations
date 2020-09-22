#Sean-scripts
#based on project by Robert Gambee


if [[ $# != 1 ]]
then
    echo "Takes 1 argument IP address"
    exit 0
fi

SOURCE="$1"


for IP in "$SOURCE"
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
echo "Deleting file on $SOURCE"
SOURCE_JOB="$(ssh "root@$SOURCE" rm -r "/data/jobs/{*[1-9a-f]*}" | tail -1)"
if [[ -z "$SOURCE_JOB" ]]
then
    echo "There are no jobs left on " $SOURCE
    ssh "root@$IP" "/etc/init.d/formule restart" > /dev/null 
    exit 2   
fi
