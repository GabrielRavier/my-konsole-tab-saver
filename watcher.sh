#!/bin/bash

# ~/src/my/konsole-tab-saver/watcher.sh

# Watches the konsole qdbus messages and saves session state changes so they can be restored easily
# https://docs.kde.org/trunk5/en/applications/konsole/command-line-options.html

# Configuration
COMMAND=''
WATCH_INTERVAL_SECONDS=15
SAVEFILE_TERMINAL="$(pwd)/current-tabs"

# Restore if asked to (not really doable rn)
# if [ "$1" = "restore" ] ; then
#     echo "Restoring..."
#     konsole --tabs-from-file ${SAVEFILE_TERMINAL} -e 'bash -c exit'&
# fi

# Function to get the current sessions and write them to a file
doOneSession() {
    local pid=$1
    local SESSIONS=$(qdbus org.kde.konsole-$pid | grep /Sessions/)
    if [[ ${SESSIONS} ]] ; then
        local CURRENT_TIME=$(date +%M:%S)
        if [[ "$CURRENT_TIME" > "11:00" ]] && [[ "$CURRENT_TIME" < "11:15" ]]; then
            cp ${SAVEFILE_TERMINAL}-$pid ${SAVEFILE_TERMINAL}-$pid-$(date +%F-%H:%M:%S).bak
        fi
        echo "# Most recent session list " $(date) > ${SAVEFILE_TERMINAL}-$pid
        for i in ${SESSIONS}; do
            local FORMAT=$(qdbus org.kde.konsole-$pid $i tabTitleFormat 0)
            local PROCESSID=$(qdbus org.kde.konsole-$pid $i processId)
            local CWD=$(pwdx ${PROCESSID} | sed -e "s/^[0-9]*: //")
            if [[ $(pgrep --parent ${PROCESSID}) ]] ; then
                CHILDPID=$(pgrep --parent ${PROCESSID})
                COMMAND=$(ps -p ${CHILDPID} -o args=)
            fi 
            echo "workdir: ${CWD};; title: ${FORMAT};; command:${COMMAND}" >> ${SAVEFILE_TERMINAL}-$pid
            COMMAND=''
        done
    fi
}

getSessions() {
    for i in $(pgrep konsole -u $USER | tr '\n' ' ')
    do
        doOneSession "$i"
    done
}



#Update the Konsole sessions every WATCH_INTERVAL_SECONDS seconds
while true; do getSessions; sleep ${WATCH_INTERVAL_SECONDS}; done
