# Dry Runs and Reading Changes

**Scope:** the two habits that make rsync safe to
use on things you care about — rehearsing every
run, and reading exactly what a run did.

## `--dry-run`: the rehearsal

`-n` (long form `--dry-run`) runs the whole
comparison and prints everything rsync *would*
do, but transfers and deletes nothing. The summary
line even labels itself:

```
sent 133 bytes  received 35 bytes  336.00 bytes/sec
total size is 36  speedup is 0.21 (DRY RUN)
```

Adopt it as a reflex:

- Before any run with `--delete` — non-negotiable;
  the next chapter shows why.
- Before any run whose destination you typed from
  memory.
- Whenever the verbose listing surprises you. The
  listing is the plan; if the plan looks wrong,
  the run would have been wrong.

**Check:** a dry run against a destination you
care about leaves it bit-for-bit untouched — the
lab's deletion dry run reported `*deleting
chapter2.txt`, and the file was still sitting in
the mirror afterwards, because a dry run *only*
reports.

## `--itemize-changes`: the annotated listing

Plain `-v` tells you *which* files moved.
`--itemize-changes` (or `-i`) prefixes each line
with an 11-character code saying *what kind* of
change and *why*. One real run, four kinds of
news:

```
>f.s....... index.html
.f...p..... style.css
>f+++++++++ assets/new-banner.txt
>f..t...... about.html
```

### Reading the code

Positions 1–2 are the headline:

| Char | Meaning |
|---|---|
| `>` | a file was sent to the destination |
| `<` | a file was received from a remote source |
| `.` | the item is not transferred — only attributes noted after it changed |
| `*` | the rest of the line is a message (e.g. `*deleting`) |

Position 2 is the item type: `f` file, `d`
directory, `L` symlink, `D` device, `S` special.

The remaining nine positions are attribute slots —
**c**hecksum (or content), **s**ize, **t**ime,
**p**ermissions, **o**wner, **g**roup, then three
you'll rarely see (reserved, **a**cl, **x**attr).
A letter in a slot means "this differs (and will be
fixed)"; a dot means it doesn't. A run of `+` signs
means the item is **newly created** — there was
nothing to compare against.

So the four lines above decode as:

- `>f.s.......` — file sent; its **size** differed.
  The normal "you edited it" line.
- `.f...p.....` — not sent; only its **permissions**
  differed, and were corrected. (In the lab the file
  had been `chmod`ded and nothing else.)
- `>f+++++++++` — a **new file**, created at the
  destination.
- `>f..t......` — sent, but only the **time**
  differed; rsync ran the comparison, found the
  content identical, and stamped the right time on
  the copy. The tell-tale of a `touch`ed file.

One subtlety the lab surfaced, worth knowing before
it puzzles you: mtimes are compared to the second.
A file re-timed by 63 milliseconds was treated as
unchanged and produced no line at all. (`--modify-window`
adjusts this comparison **(documented)**; the
default is right for almost everyone.)

### When nothing is wrong, it says so

Run the same command twice in a row. The second
listing is empty:

```
$ rsync -av --itemize-changes site/ site-copy/
sending incremental file list

sent 215 bytes  received 13 bytes  456.00 bytes/sec
total size is 118  speedup is 0.52
```

An empty list with a clean footer is rsync's
all-clear — the trees match by every measure the
run was asked to check. Piping itemised output to a
log is also how you get an audit trail of a
recurring sync for free: the codes are stable,
greppable, and dated by your scheduler, not by
rsync.
