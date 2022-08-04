#!/bin/sh

set -o pipefail
program=$(basename "$0")
fail() { echo "$1"; exit 1; }

for f in *; do
	expr "$f" : [Tt][Oo][Dd][Oo] > /dev/null && todo_file="$f" && break
done

[ -n $todo_file ] || todo_file="${TODO_FILE:-${PWD}/TODO}"

todo_alt_file="${TODO_ALT_FILE:-${PWD}/REMEMBER}"
done_file="${DONE_FILE:-${PWD}/DONE}"

usage() {
	echo "usage: $program TASK"
	echo "       $program [-d LINENUM] [-e] [-Ss QUERY]"
}

# t_done(linenum, done)
t_done() {
	[ -f "$todo_file" ] || fail "File not found"
	linenum=$1; done=$2
	tmpfile=$(mktemp)
	if [ "$done" -eq 1 ]; then
		sed -n "${linenum}p" "$todo_file" >> "$done_file"
	fi
	sed "${linenum}d" "$todo_file" > "$tmpfile"
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
