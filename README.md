# t_done

The simplest CLI todo list manager ever.

- Reads and prints todos to the command line from any [GFM][] /
  [Org Mode][] checklist.
- Search todos by regular expression.
- Optionally include completed todos.
- Automatically orders todos with dates at top.
- Displays past-due todos with \*\*asterisks\*\*
- Mark todos done.
- 100% Bash.

This README file is a todo list.

[gfm]: https://help.github.com/articles/writing-on-github/
[org mode]: http://orgmode.org

## Usage

The todo list is set by the environment variable `TODO_FILE`. The
following assumes you've symlinked `t_done.sh` to `t` somewhere in your
`$PATH`.

command                 | result
------------------------|-----------------------------------------------
`t buy milk`            | add todo "buy milk"
`t`                     | print incomplete todos
`t -a`                  | print all todos
`t -D`                  | print all done todos
`t -s call`             | print all todos matching "call"
`t /call`               | same as above
`t -s "call|email"`     | print all todos matching "call" or "email"
`t -D -s read`          | print all done todos matching "read"
`t -d 12`               | mark todo item 12 as done
`t -s read -d 3`        | mark todo item 3 within todos matching "read" as done
`t -d burn`             | mark all todo items matching "burn" as done
`t -s burn -d .`        | same as above
`t -e`                  | edit `$TODO_FILE` in `$EDITOR`
`t -t +1w buy racecar`  | add todo "buy racecar" due a week from today
`t -T sell horse`       | add todo "sell horse" due today

## Todo

- [X] store $query for every flag
- [X] add -D flag for only show done
- [X] order due dates first
- [X] add regex group 3 (text after date)
- [X] add case sensitivity
- [X] add date options
- [X] add ** for due/overdue todos
- [X] allow marking done by regex
- [X] print long output with $PAGER
- [ ] print to $PAGER without mktemp
- [ ] add --long-flags
- [ ] allow $TODO_FILE or $HOME/.t_donerc
- [X] conform to quoting conventions
