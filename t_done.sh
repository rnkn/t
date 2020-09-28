#! /usr/bin/env bash

usage="$(cat <<'EOF'
usage:
    t [-aD]
    t [-aD] [-s REGEX_STRING] [-d [INTEGER|REGEX_STRING]]
    t /REGEX_STRING
    t [-T] [-t [+|-]VAL[ymwd]] STRING

examples:
    t                     print incomplete todos
    t -a                  print all todos
    t -D                  print all done todos
    t -s call             print all todos matching "call"
    t /call               same as above
    t -s "call|email"     print all todos matching "call" or "email"
    t -D -s read          print all done todos matching "read"
    t -d 12               mark todo item 12 as done
    t -s read -d 3        mark todo item 3 within todos matching "read" as done
    t -d burn             mark all todos matching "burn" as done
    t -s burn -d .        same as above
    t -k 7                delete todo item 7
    t -k bunnies          delete all todos matching "bunnies"
    t -s bunnies -k .     same as above
    t -e                  edit $TODO_FILE in $EDITOR
    t -T sell horse       add todo "sell horse" due today
    t -t 20d celebrate    add todo "celebrate" due on the 20th of this month
    t -t +1w buy racecar  add todo "buy racecar" due a week from today
                            (for date syntax, see date manual entry)
    t -n                  print unnumbered output (suitable for redirection)
EOF
)"

IFS=$'\n'
red='\e[0;31m'
clear='\e[0m'
str_prefix='- [ ] '
re_todofile='[Tt][Oo][Dd][Oo](\.[^.]+)?'
re_todo='^- \[ ] '
re_done='^- \[[xX]] '
re_either='^- \[[ xX]] '
re_date='[0-9]{4}-[0-9]{2}-[0-9]{2}'
lines=$(tput lines)

for file in *
do
    [[ $file =~ $re_todofile ]] && todofile="$file"
done

if [[ ! $todofile && -r $TODO_FILE ]]
then todofile="$TODO_FILE"
elif [[ ! $todofile ]]
then printf 'No todo file found or environment variable TODO_FILE not set!\n'
     exit 3
fi

function t_read {
    if [[ $onlydone ]]
    then
        re_prefix=$re_done
    elif [[ $showall ]]
    then
        re_prefix=$re_either
    else
        re_prefix=$re_todo
    fi

    local casematch
    [[ ! $* =~ [A-Z] ]] && casematch='--ignore-case'
    todo_list=($(grep -E $casematch "$re_prefix.*($*)" "$todofile"))
    local due_list
    local item
    for i in "${!todo_list[@]}"
    do
        if [[ ${todo_list[i]} =~ $re_date ]]
        then
            item="${todo_list[i]}"
            due_list+=("$item")
            unset todo_list[i]
        fi
    done

    due_list=($(printf "%s\n" "${due_list[@]}" | sed -E "s/.*($re_date).*/\1&/" | sort -g | sed -E "s/^$re_date//"))
    todo_list=(${due_list[@]} ${todo_list[@]})
}

function t_print {
    t_read "$query"

    local n=1
    local buffer=$(mktemp)
    local n_total=${#todo_list[@]}
    local n_width=${#n_total}

    for todo in "${todo_list[@]}"
    do
        if [[ $todo =~ $re_todo && $todo =~ $re_date ]]
        then
            local date=${BASH_REMATCH//-}
            local today=$(date +%Y%m%d)
            (( date <= today )) && todo=$(sed -E "s/($re_prefix)(.*)/\1** \2 **/" <<< "$todo")
        fi

        if [[ $export ]]
        then
            printf "%s\n" "${todo}" >> "$buffer"
        else
            printf "%${n_width}s %s\n" "$n" "${todo#- }" >> "$buffer"
        fi
        (( n++ ))
    done

    if (( lines <= n_total ))
    then ${PAGER:-less} -X < "$buffer"
    else cat "$buffer"
    fi

    rm "$buffer"
}

function t_select {
    if [[ $1 =~ ^[0-9]+$ ]]
    then
        selection=${todo_list[(( $1 - 1 ))]}
    else
        local casematch
        [[ ! $@ =~ [A-Z] ]] && casematch='--ignore-case'
        selection=($(printf "%s\n" "${todo_list[@]}" | grep $casematch "$@" ))
    fi
}

function t_done {
    t_read "$query"
    t_select "$1"

    for todo in "${selection[@]}"
    do
        todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< "$todo")
        sed -i '' "/$todo/s/^- \[ ]/- \[X]/" "$todofile"
    done
}

function t_kill {
    t_read "$query"
    t_select "$1"

    for todo in "${selection[@]}"
    do
        todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< "$todo")
        sed -i '' "/$todo/d" "$todofile"
    done
}

function t_toggle {
    t_read "$query"
    t_select "$1"

    for todo in "${selection[@]}"
    do
        if [[ $todo =~ $re_done ]]
        then
            todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< "$todo")
            sed -i '' "/$todo/s/^- \[[xX]]/- [ ]/" "$todofile"
        elif [[ $todo =~ $re_todo ]]
        then
            todo=$(sed 's/[][\/$*.^|]/\\&/g' <<< "$todo")
            sed -i '' "/$todo/s/^- \[ ]/- [X]/" "$todofile"
        fi
    done
}

function t_openurl {
    t_read "$query"
    t_select "$1"

    urls=($(printf "%s\n" "${selection[@]}" | grep -Eo "https?://[^ ]+"))
    for url in "${urls[@]}"
    do
        open "$url" && echo "t: opening ${url} ..."
    done
}

while getopts ':heaDns:k:d:z:u:Tt:' opt
do
    case $opt in
        (h) printf "%s\n" "$usage"
            exit 0;;
        (e) ${EDITOR:-nano} "$todofile"
            exit 0;;
        (a) showall=0;;
        (D) onlydone=0;;
        (n) export=0;;
        (s) query=$OPTARG;;
        (k) kill=$OPTARG;;
        (d) markdone=$OPTARG;;
        (z) toggle=$OPTARG;;
        (u) openurl=$OPTARG;;
        (T) due=" $(date +%F)";;
        (t) due=" $(date -v $OPTARG +%F)";;
        (:) printf "t: option -%s requires an argument\n" "$OPTARG"
            exit 2;;
        (*) printf "t: unrecognized option -%s\n\n" "$OPTARG"
            printf "%s\n" "$usage"
            exit 1;;
    esac
done

shift $(( OPTIND - 1 ))

[[ $@ =~ ^\/ ]] && query="${*#/}"

if [[ -n $openurl ]]
then
    t_openurl "$openurl"
elif [[ -n $markdone ]]
then
    t_done "$markdone"
elif [[ -n $toggle ]]
then
    t_toggle "$toggle"
elif [[ -n $kill ]]
then
    t_kill "$kill"
elif [[ -n $query ]]
then
    t_print "$query"
elif [[ -n $@ ]]
then
    todo="$str_prefix$*$due"
    echo $todo >> "$todofile"
else
    t_print
fi
