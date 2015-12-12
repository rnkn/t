#! /bin/bash

if [[ -z "$TODO_FILE" ]]
then
    echo 'Environment variable TODO_FILE not set!'
    exit 3
fi

PREFIX='- [ ] '
RE_DATE='[0-9]{4}-[0-9]{2}-[0-9]{2}'
IFS=$'\n'
LINES=$(tput lines)
useage='useage: t [-aD] [-s regex_match] [-d [integer|regex_match]]
         /regexp_match
         [-T] [-t [+|-]val[ymwd]] todo_string\n'

function t_read {
    if [[ $showall ]]
    then RE_PREFIX='^- \[[ xX]] '
    elif [[ $onlydone ]]
    then RE_PREFIX='^- \[[xX]] '
    else RE_PREFIX='^- \[ ] '
    fi

    local casematch
    if [[ ! $@ =~ [A-Z] ]]
    then casematch='--ignore-case'
    fi

    list=($(grep -E $casematch "$RE_PREFIX.*($@)" $TODO_FILE))
    n_total=${#list[@]}
    n_length=${#n_total}

    local due_list=()
    for i in ${!list[@]}
    do
        if [[ ${list[i]} =~ $RE_DATE ]]
        then item=${list[i]}
             due_list+=($item)
             unset list[i]
        fi
    done

    due_list=($(printf "%s\n" ${due_list[@]} | sed -E "s/(.*)($RE_DATE)(.*)/\2@@\1@@\3/" | sort -g | sed -E "s/($RE_DATE)@@(.*)@@(.*)/\2\1\3/"))
    list=(${due_list[@]} ${list[@]})
}

function t_print {
    t_read $@

    local n=1
    local buffer=$(mktemp)
    for todo in ${list[@]}
    do
        if [[ $todo =~ $RE_DATE ]]
        then
            local date=${BASH_REMATCH//-}
            local today=$(date +%Y%m%d)
            if (( $date <= $today ))
            then todo=$(sed -E "s/($RE_PREFIX)(.*)/\1**\2**/" <<< $todo)
            fi
        fi
        printf "%${n_length}s %s\n" $n ${todo#- } >> $buffer
        ((n++))
    done

    if (( $LINES <= $n_total ))
    then cat $buffer | ${PAGER:-less}
    else cat $buffer
    fi

    rm $buffer
}

function t_done {
    t_read $query

    local done_list
    if [[ $1 =~ ^[0-9]+$ ]]
    then done_list=${list[(( $1 - 1 ))]}
    else
        local casematch
        if [[ ! $@ =~ [A-Z] ]]
        then casematch='--ignore-case'
        fi
        done_list=($(printf "%s\n" ${list[@]} | grep $casematch $@ ))
    fi

    for todo in ${done_list[@]}
    do
        todo=${todo#- \[ \] }
        todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< $todo)
        sed -i '' "/$todo/ s/^- \[ ]/- \[X]/" $TODO_FILE
    done
}

while getopts ':abBs:d:DehTt:' opt
do
    case $opt in
        b) backburner=0
           ;;
        B) onlybackburner=0
           ;;
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
        e) $EDITOR $TODO_FILE
           exit 0
           ;;
        h) echo -e $useage
           exit 0
           ;;
        :) echo "t: Option -$OPTARG requires an argument"
           exit 2
    esac
done

shift $((OPTIND - 1))

if [[ $@ =~ ^\/ ]]
then query=${@#/}
fi

if [[ -n $markdone ]]
then t_done $markdone
elif [[ -n $query ]]
then t_print $query
elif [[ -n $@ ]]
then todo="$PREFIX$@$due"
     echo $todo >> $TODO_FILE
else t_print
fi
