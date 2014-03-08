#! /bin/bash

# printf "Enter docroot and environment in the form of docroot.envoronment:\n"
# read hostenv
hostenv='metrota2'
# printf "Enter log name without extension:\n"
# read logname
logname='error'
# printf "Enter search string:\n"
# read searchstring
searchstring='5\d\d'


# declare -a servers=();


OIFS="${IFS}"
NIFS=$'\n'

IFS="${NIFS}"

output=$(aht @"${hostenv}" 2>/dev/null)

for LINE in ${output} ; do
  # echo "---- ${LINE}"
  [[ ${LINE} =~ (staging)-[0-9]+|(\[(.*?): .*?\]) ]]
  if [ "${BASH_REMATCH[0]}" != "" ]
  then
    echo "${BASH_REMATCH[0]}"

    # ssh "${BASH_REMATCH[1]}":/var/log/sites/"$hostenv"/logs/"${BASH_REMATCH[0]}" grep -c "$searchstring" "$logname".log
    echo "-----------------------------------------------------"
  fi
done


IFS="${OIFS}"
exit 0
