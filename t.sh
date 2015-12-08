#! /bin/bash

if [[ -z "$TODO_FILE" ]]
then
    echo "Environment variable TODO_FILE not set!"
    exit 3
fi

if [[ ! -r "$TODO_FILE" ]]
then
    echo "TODO_FILE not found!"
    exit 4
fi

prefix="- [ ] "
IFS=$'\n'

function t_read {
    local re
    if [[ $showall ]]
    then re='^- \[[ xX]\]'
    else re='^- \[ \]'
    fi
    list=($(grep -E --ignore-case "$re.*($@)" $TODO_FILE))
    ntotal=${#list[@]}
    nlength=${#ntotal}
}

function t_print {
    t_read "$@"
    local n=1
    for todo in ${list[@]}
    do
        printf "%${nlength}s %s\n" "$n" "${todo#- }"
        ((n++))
    done
}

function t_done {
    t_read
    local todo
    if [[ $1 =~ [0-9]+ ]]
    then
        local n=$(($1-1))
        local todo
        todo=${list[$n]}
        todo=${todo#- \[ \] }
    fi
    if [[ -n "$todo" ]]
    then sed -i -- "/$todo/ s/- \[ \]/- \[X\]/" $TODO_FILE
    else echo "Todo $1 not found!"
    fi
}

while getopts "as:d:e" opt
do
    case $opt in
        a)
            showall=0
            ;;
        s)
            t_print $OPTARG
            exit 0
            ;;
        d)
            t_done $OPTARG
            exit 0
            ;;
        e)
            "$EDITOR" "$TODO_FILE"
            exit 0
            ;;
    esac
done

shift "$((OPTIND-1))"

if [[ -n $@ ]]
then
    if [[ $@ =~ ^\/ ]]
    then
        t_print "${@#/}"
    # elif [[ $@ =~ ^\. ]]
    # then
    #     t_done "${@#.}"
    else
        todo="$prefix$@"
        echo "$todo" >> "$TODO_FILE"
    fi
else
    t_print
fi
