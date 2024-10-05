#! /bin/sh

# Copyright (c) 2015-2024 Paul W. Rankin <rnkn@rnkn.xyz>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

usage() {
	cat <<EOF
usage:
    t [-aDehn]
    t [-T] STRING
    t [-aD] [-s REGEX_STRING] [-d [INTEGER|REGEX_STRING]]
    t [-aD] [-s REGEX_STRING] [-k [INTEGER|REGEX_STRING]]
    t [-aD] [-s REGEX_STRING] [-b [INTEGER|REGEX_STRING]]
    t [-aD] [-s REGEX_STRING] [-z [INTEGER|REGEX_STRING]]

examples:
    t                     print incomplete todos
    t -a                  print all todos
    t -D                  print all done todos
    t -s call             print all todos matching "call"
    t -s "call|email"     print all todos matching "call" or "email"
    t -D -s read          print all done todos matching "read"
    t -d 12               mark todo item 12 as done
    t -s read -d 3        mark todo item 3 within todos matching "read" as done
    t -d burn             mark all todos matching "burn" as done
    t -s burn -d .        same as above
    t -k 7                delete todo item 7
    t -k bunnies          delete all todos matching "bunnies"
    t -s bunnies -k .     same as above
    t -e                  edit TODO_FILE in $EDITOR
    t -T sell horse       add todo "sell horse" due today
    t -n                  print unnumbered output (suitable for redirection)
EOF
	exit 1
}

re_todo_file='[Tt][Oo][Dd][Oo].*'
re_todo='^- \[ ] '
re_done='^- \[[xX]] '
re_either='^- \[[ xX]] '
re_date='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'

for f in *; do
	expr "$f" : "$re_todo_file" > /dev/null && todo_file="$f" && break
done

if [ ! "$todo_file" ]; then
	if [ -r "$TODO_FILE" ]; then
		todo_file="$TODO_FILE"
	else
		echo 'No todo file found'
		exit 1
	fi
fi

# t_read(query)
# returns: sorted list of matching todos
t_read() {
	query="$*"
	casematch=
	expr "$query" : '\(.*[A-Z].*\)' > /dev/null || casematch='-i'
	todo_list=$(grep $wholeword $casematch "$re_prefix.*$*" "$todo_file")

	if [ -n "$todo_list" ]; then
		due_list=$(echo "$todo_list" | grep "$re_date")
		todo_list=$(echo "$todo_list" | grep -v "$re_date")
		due_list=$(echo "$due_list" | sed -E "s/.*($re_date).*/\1&/" |
					   sort -n | sed -E "s/^$re_date//")

		# printf '%s\n%s\n' "$due_list" "$todo_list"
		if [ -n "$due_list" ] && [ -n "$todo_list" ]; then
			printf '%s\n%s\n' "$due_list" "$todo_list"
		elif [ -n "$due_list" ]; then
			printf '%s\n' "$due_list"
		else
			printf '%s\n' "$todo_list"
		fi
	fi
}

# t_print(prefix)
# returns: todo list printed to stdout
t_print() {
	input=$(cat)
	if [ -n "$input" ]; then
		n=1
		n_width=$(echo "$input" | wc -l | xargs | wc -c)

		echo "$input" | while read -r todo; do
			date=$(expr "$todo" : ".*\($re_date\)" | sed 's/-//g')
			today=

			if [ -n "$date" ] && [ -z "$onlydone$showall" ]; then
				today=$(date +%Y%m%d)
				if [ "$today" -ge "$date" ]; then
					todo=$(echo "$todo" |
							   sed -E "s/($re_prefix)(.*)/\1** \2 **/")
				fi
			fi

			if [ -n "$export" ]; then
				printf "%s\n" "${todo}"
			else
				printf "%${n_width}s %s\n" "$n" "${todo#- }"
			fi
			n=$(( n + 1 ))
		done
	fi
}

# t_select(number|regex)
# returns: selected todos
t_select() {
	if expr "$1" : ^[0-9]*$ > /dev/null; then
		sed -n "$1p"
	else
		casematch=
		expr "$1" : '.*[A-Z].*' > /dev/null || casematch='-i'
		grep $casematch "$*"
	fi
}

# t_done(number|regex)
# returns: altered todo_file
t_done() {
	 t_select "$1" |
		while read -r todo; do
			tmp=$(mktemp)
			awk -v str="$todo" \
				'$0 == str { gsub (/- \[ ]/, "- [X]") } { print }' \
				"$todo_file" > "$tmp"
			mv "$tmp" "$todo_file"
		done
}

# t_kill()
t_kill() {
	t_select "$1" |
		while read -r todo; do
			tmp=$(mktemp)
			awk -v str="$todo" '$0 != str' "$todo_file" > "$tmp"
			mv "$tmp" "$todo_file"
		done
}

t_toggle() {
	t_select "$1" |
		while read -r todo; do
			tmp=$(mktemp)
			check=
			expr "$todo" : "$re_done" > /dev/null &&
				check='- [ ]' || check='- [X]'
			awk -v str="$todo" -v check="$check" \
				'$0 == str { gsub (/- \[[ xX]]/, check) } { print }' \
				"$todo_file" > "$tmp"
			mv "$tmp" "$todo_file"
		done
}

t_openurl() {
	t_select "$1" | grep -Eo "https?://[^ ]+" | xargs open
}

while getopts ':ab:Dd:ehk:nSs:Tz:' opt; do
	case $opt in
		(h) usage ;;
		(a) showall=0;;
		(b) openurl=$OPTARG;;
		(D) onlydone=0;;
		(d) markdone=$OPTARG;;
		(e) ${EDITOR:-vi} "$todo_file"; exit 0;;
		(k) kill=$OPTARG;;
		(n) export=0;;
		(S) wholeword=-w;;
		(s) query=$OPTARG;;
		(T) due=" $(date +%F)";;
		(z) toggle=$OPTARG;;
		(:) printf "t: option -%s requires an argument\n" "$OPTARG"
			exit 2 ;;
		(*) printf "t: unrecognized option -%s\n\n" "$OPTARG"
			usage ;;
	esac
done

shift "$(( OPTIND - 1 ))"

if [ -n "$onlydone" ]; then
	re_prefix="$re_done"
elif [ -n "$showall" ]; then
	re_prefix="$re_either"
else
	re_prefix="$re_todo"
fi

if	 [ -n "$markdone" ]; then t_read "$query" | t_done "$markdone"
elif [ -n "$toggle" ]; then t_read "$query" | t_toggle "$toggle"
elif [ -n "$kill" ]; then t_read "$query" | t_kill "$kill"
elif [ -n "$openurl" ]; then t_read "$query" | t_openurl "$openurl"
elif [ -n "$query" ]; then t_read "$query" | t_print "$re_prefix"
elif [ -n "$*" ]; then
	echo "- [ ] $*${due}" >> "$todo_file"
else t_read | t_print "$re_prefix"
fi
