#! /bin/bash

if [[ -z "$TODO_FILE" ]]
then
    printf 'Environment variable TODO_FILE not set!\n'
    exit 3
fi

IFS=$'\n'
prefix='- [ ] '
re_date='[0-9]{4}-[0-9]{2}-[0-9]{2}'
lines=$(tput lines)
useage='useage: t [-aD] [-s regex_match] [-d [integer|regex_match]]
         /regexp_match
         [-T] [-t [+|-]val[ymwd]] todo_string'

function t_read {
    if [[ $showall ]]
    then re_prefix='^- \[[ xX]] '
    elif [[ $onlydone ]]
    then re_prefix='^- \[[xX]] '
    else re_prefix='^- \[ ] '
    fi

    local _casematch
    if [[ ! $@ =~ [A-Z] ]]
    then _casematch='--ignore-case'
    fi

    list=($(grep -E $_casematch "$re_prefix.*($*)" "$TODO_FILE"))
    n_total=${#list[@]}
    n_length=${#n_total}

    local _due_list
    for i in "${!list[@]}"
    do
        if [[ ${list[i]} =~ $re_date ]]
        then item=${list[i]}
             _due_list+=($item)
             unset list[i]
        fi
    done

    _due_list=($(printf "%s\n" "${_due_list[@]}" | sed -E "s/(.*)($re_date)(.*)/\2@@\1@@\3/" | sort -g | sed -E "s/($re_date)@@(.*)@@(.*)/\2\1\3/"))
    list=(${_due_list[@]} ${list[@]})
}

function t_print {
    t_read "$@"

    local _n=1
    local _buffer=$(mktemp)
    for todo in "${list[@]}"
    do
        if [[ $todo =~ $re_date ]]
        then
            local date=${BASH_REMATCH//-}
            local today=$(date +%Y%m%d)
            if (( date <= today ))
            then todo=$(sed -E "s/($re_prefix)(.*)/\1**\2**/" <<< "$todo")
            fi
        fi
        printf "%${n_length}s %s\n" $_n "${todo#- }" >> "$_buffer"
        ((_n++))
    done

    if (( lines <= n_total ))
    then ${PAGER:-less} < "$_buffer"
    else cat "$_buffer"
    fi

    rm "$_buffer"
}

function t_done {
    t_read "$query"

    local _done_list
    if [[ $1 =~ ^[0-9]+$ ]]
    then _done_list=${list[(( $1 - 1 ))]}
    else
        local _casematch
        if [[ ! $@ =~ [A-Z] ]]
        then _casematch='--ignore-case'
        fi
        _done_list=($(printf "%s\n" "${list[@]}" | grep $_casematch "$@" ))
    fi

    for todo in "${_done_list[@]}"
    do
        todo=${todo#- \[ \] }
        todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< "$todo")
        sed -i '' "/$todo/ s/^- \[ ]/- \[X]/" "$TODO_FILE"
    done
}

while getopts ':aDs:d:Tt:he' opt
do
    case $opt in
        a) showall=0
           ;;
        D) onlydone=0
           ;;
        s) query=$OPTARG
           ;;
        d) markdone=$OPTARG
           ;;
        T) due=" $(date +%F)"
           ;;
        t) due=" $(date -v $OPTARG +%F)"
           ;;
        h) printf "%s\n" "$useage"
           exit 0
           ;;
        e) $EDITOR "$TODO_FILE"
           exit 0
           ;;
        :) printf "Option -%s requires an argument\n" "$OPTARG"
           exit 2
    esac
done

shift $(( OPTIND - 1 ))

if [[ $@ =~ ^\/ ]]
then query=${*#/}
fi

if [[ -n $markdone ]]
then t_done "$markdone"
elif [[ -n $query ]]
then t_print "$query"
elif [[ -n $@ ]]
then todo="$prefix$*$due"
     echo $todo >> "$TODO_FILE"
else t_print
fi
