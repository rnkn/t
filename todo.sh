#!/bin/sh

program=$(basename "$0")
fail() { echo "$1"; exit 1; }

todo_file="${TODO_FILE:-${PWD}/TODO}"

test -f "$todo_file" || fail "TODO_FILE not found"

usage() {
	echo "usage: $program TASK"
	echo "       $program [-d LINENUM] [-e] [-Ss QUERY]"
}

# t_done(int)
t_done() {
	int=$1
	tmpfile=$(mktemp)
	sed -n "${int}!p" "$todo_file" > "$tmpfile"
	mv "$todo_file" "${todo_file}~"
	mv "$tmpfile" "$todo_file"
}

t_print() {
	lines=$(wc -l < "$todo_file")
	width=$(echo $lines | wc -c)
	nl -s' ' -w"$width" "$todo_file"
}

main() {
	if getopts hed:S:s: opt; then
		case "$opt" in
			(e)	$EDITOR "$todo_file"
				exit ;;
			(d)	t_done "$OPTARG"
				exit ;;
			(S)	t_print | grep -iw "$OPTARG"
				exit ;;
			(s)	t_print | grep -i "$OPTARG"
				exit ;;
			(h)	usage
				exit ;;
			(?)	usage
				exit 1 ;;
		esac
	elif test -n "$1"; then
		echo "$@" >> "$todo_file"
	else
		t_print
	fi
}

main "$@"
