echo "Enter a printer IP"
read pIP
echo "Enter printer number start:"
read start
echo "How many printers"
read end

INPUT=f3list.csv
OLDIFS=$IFS
IFS=','
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
declare -i loop=1
while read flname dob
do
        $serials[loop] = $flname
        ips[loop]=$dob
        loop=$(( loop + 1 ))
done < $INPUT
IFS=$OLDIFS

COUNTER=0
while [  $COUNTER -lt $end ]; do
        echo "Uploading to ${serials[COUNTER + $start]}"
        bash delete_all.sh ${ips[COUNTER + $start]}
        let COUNTER=COUNTER+1
done
