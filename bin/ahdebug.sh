#!/bin/bash

source "$(dirname $0)/../lib/common-functions.shinc"
source "$(dirname $0)/../lib/debug-functions.shinc"

#
# Process debugging steps
#
function debug_main()
{
    shellInit
    ahdebugInit
    shellMessage Starting Debug

    SCRIPT_TASKS=(
        catalogVars
        catalogDotfiles
        catalogSshDir
        catalogPrivateKeys
        catalogPrivateKeysInAgent
        catalogPublicKeys
        catalogBastionFunction
        catalogShellSourcing
        catalogConfig
    )

    for (( i=0; i<${#SCRIPT_TASKS[@]}; ++i )) do
        shellMessage Running task: ${SCRIPT_TASKS[$i]}
        eval ${SCRIPT_TASKS[$i]} || shellFatal  "${SCRIPT_TASKS[$i]} failed ($?). Exiting."
    done

    shellError $AHDEBUG_ANALYSIS

    local logfile="${HOME}/Desktop/ahdebug-${USER}-$(date -u +%F-%s).log"
    /bin/mv "${SCRIPT_TEMP}/log" "${logfile}"
    shellMessage "Please attach this logfile to your TAC ticket: ${logfile}"
}

debug_main $@
