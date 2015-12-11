#! /bin/bash

if [[ -z "$TODO_FILE" ]]
then
    echo 'Environment variable TODO_FILE not set!'
    exit 3
fi

prefix='- [ ] '
IFS=$'\n'
useage="useage: t todo\n
    t -s query\n
    t -d [0-9]+"

function t_read {
    local re_prefix
    local re_date='[0-9]{4}-[0-9]{2}-[0-9]{2}'
    if [[ $showall ]]
    then re_prefix='^- \[[ xX]] '
    elif [[ $onlydone ]]
    then re_prefix='^- \[[xX]] '
    else re_prefix='^- \[ ] '
    fi

    if [[ ! $@ =~ [A-Z] ]]
    then casematch='--ignore-case'
    fi

    list=($(grep -E $casematch "$re_prefix.*($@)" $TODO_FILE))
    n_total=${#list[@]}
    n_length=${#n_total}

    local due_list=()
    for i in ${!list[@]}
    do
        if [[ ${list[i]} =~ $re_date ]]
        then item=${list[i]}
             local date=${BASH_REMATCH//-}
             local today=$(date +%Y%m%d)
             if (( $date <= $today ))
             then item=$(sed -E "s/($re_prefix)(.*)/\1**\2**/" <<< $item)
             fi
             due_list+=($item)
             unset list[i]
        fi
    done

    due_list=($(printf "%s\n" ${due_list[@]} | sed -E "s/(.*)($re_date)(.*)/\2@@\1@@\3/" | sort -g | sed -E "s/($re_date)@@(.*)@@(.*)/\2\1\3/"))
    list=(${due_list[@]} ${list[@]})
}

function t_print {
    t_read $@

    local n=1
    for todo in ${list[@]}
    do
        printf "%${n_length}s %s\n" $n ${todo#- }
        ((n++))
    done
}

function t_done {
    t_read $query

    local done_list
    if [[ $@ =~ ^[0-9]+$ ]]
    then done_list=${list[(($1 - 1))]}
    else done_list=($(printf "%s\n" ${list[@]} | grep $@ ))
    fi

    for todo in ${done_list[@]}
    do
        todo=${todo#- \[ \] }
        todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< $todo)
        sed -i '' "/$todo/ s/^- \[ ]/- \[X]/" $TODO_FILE
    done

    if [[ -n $todo ]]
    then sed -i '' "/$todo/ s/^- \[ ]/- \[X]/" $TODO_FILE
    fi
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
then todo="$prefix$@$due"
     echo $todo >> $TODO_FILE
else t_print
fi
