#! /bin/bash

if [[ -z "$TODO_FILE" ]]
then
    echo 'Environment variable TODO_FILE not set!'
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
    then re='^- \[[ xX]]'
    elif [[ $onlydone ]]
    then re='^- \[[xX]]'
    else re='^- \[ ]'
    fi

    if [[ ! $@ =~ [A-Z] ]]
    then casematch='--ignore-case'
    fi

    list=($(grep -E $casematch "$re.*($@)" $TODO_FILE))
    ntotal=${#list[@]}
    nlength=${#ntotal}

    due_list=()
    for i in ${!list[@]}
    do
        if [[ ${list[i]} =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]
        then
            due_list+=(${list[i]})
            unset list[i]
        fi
    done

    due_list=($(printf "%s\n" ${due_list[@]} | sed -E "s/(.*)([0-9]{4}-[0-9]{2}-[0-9]{2})(.*)/\2@@\1@@\3/" | sort -g | sed -E "s/([0-9]{4}-[0-9]{2}-[0-9]{2})@@(.*)@@(.*)/\2\1\3/"))
    list=(${due_list[@]} ${list[@]})
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
        local n=$(($1 - 1))
        local todo
        todo=${list[$n]}
        todo=${todo#- \[ \] }
    fi
    if [[ -n "$todo" ]]
    then sed -i -- "/$todo/ s/- \[ \]/- \[X\]/" $TODO_FILE
    else echo "Todo $1 not found!"
    fi
}

while getopts 'as:d:De' opt
do
    case $opt in
        a) showall=0
           ;;
        D) onlydone=0
           ;;
        s) t_print $OPTARG
           exit 0
           ;;
        d) t_done $OPTARG
           exit 0
           ;;
        e) "$EDITOR" "$TODO_FILE"
           exit 0
           ;;
    esac
done

shift $((OPTIND - 1))

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
