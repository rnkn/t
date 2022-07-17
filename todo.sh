#!/bin/sh

program=$(basename "$0")
fail() { echo "$1"; exit 1; }

todo_file="${TODO_FILE:-${PWD}/TODO}"

test -f "$todo_file" || fail "TODO_FILE not found"

usage() {
	echo "usage: $program [-e]"
	echo "       $program [-d NUM]"
	echo "       $program TASK"
}

# t_done(int)
t_done() {
	int=$1
	tmpfile=$(mktemp)
	sed -n "${int}!p" "$todo_file" > "$tmpfile"
	mv "$tmpfile" "$todo_file"
}

t_print() {
	lines=$(wc -l < "$todo_file")
	width=$(echo $lines | wc -c)
	nl -s' ' -w"${width}" "$todo_file"
}

main() {
	if getopts hed: opt; then
		case "$opt" in
			(e)	$EDITOR "$todo_file"
				exit ;;
			(d)	t_done "$OPTARG"
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
