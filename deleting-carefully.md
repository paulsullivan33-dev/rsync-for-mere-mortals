# Deleting, Carefully

**Scope:** the option that makes rsync a mirror
instead of an accumulator — and the nets to string
under it.

## What `--delete` actually promises

Without `--delete`, rsync only ever adds and
updates. Files you removed from the source live on
in the destination forever — a copy, not a mirror.
With `--delete`, rsync removes destination files
that have no counterpart in the source. The trees
*match*. That is the whole promise, and it cuts
exactly as deep as it sounds: anything in the
destination that isn't in the source is deleted —
including the file you saved there last week
forgetting it existed nowhere else, and including
*everything* if you point the command at the wrong
source and the "source" is an empty directory.

The canonical accident is a mirror command whose
source is an unmounted drive: the directory exists,
it's empty, rsync runs happily, and the mirror is
faithfully emptied. Nothing in rsync can save you
from a command that correctly does the wrong thing.
The habits below can.

## Habit one: dry-run every deletion first

From the lab. A file was removed from the source;
the mirror still held it:

```
$ rsync -av --delete --dry-run --itemize-changes docs/ docs-mirror/
sending incremental file list
*deleting   chapter2.txt
...
total size is 36  speedup is 0.21 (DRY RUN)

$ ls docs-mirror/   (chapter2.txt still there — the dry run changed nothing)
appendix.txt  chapter1.txt  chapter2.txt  readme.txt
```

The `*deleting` line names precisely what would
die. Read the dry run's deleting lines the way you'd
read a `rm` command you were about to sign. Only
then, the real run:

```
$ rsync -av --delete docs/ docs-mirror/
sending incremental file list
deleting chapter2.txt
```

## Habit two: keep what you'd overwrite

`--delete` governs files that vanish; `--backup`
governs files that get *replaced*. Point
`--backup-dir` at a directory and every file rsync
overwrites or deletes is first moved there, under
its relative path:

```
$ rsync -av --backup --backup-dir=../rescued docs/ docs-mirror/
sending incremental file list
readme.txt

$ find rescued -type f | sort  (the replaced first edition, kept)
rescued/readme.txt
$ cat rescued/readme.txt
the readme
```

The new edition went to the mirror; the first
edition survived in `rescued/`. Notes that matter:
the backup directory is relative to the
*destination* unless given as an absolute path, it
should live outside the tree being mirrored (or be
excluded), and it grows without bound unless you
prune it — it is a safety net, not an archive. A
`--suffix` (default `~`) instead appends to the
replaced file's name in place **(documented)**.

## Habit three: cap the blast radius

`--max-delete=N` tells rsync to stop deleting
after N files. The lab planted three strays in a
mirror and capped deletions at one:

```
$ rsync -av --delete --max-delete=1 docs/ docs-mirror/
sending incremental file list
deleting stray3.txt
./
Deletions stopped due to --max-delete limit (2 skipped)
...
rsync error: the --max-delete limit stopped deletions (code 25) at main.c(1356) [sender=3.2.7]
```

It deleted one file, skipped two, and exited with
**code 25** — a loud failure, not a quiet partial
success, so a scheduled job's error reporting will
notice. As a tripwire on an automated mirror ("if
more than 50 files would die, something upstream is
wrong — stop and let a human look"), it earns its
keep.

## The fine print **(documented)**

- Files *excluded* from the transfer are protected
  from deletion by default; `--delete-excluded`
  removes that protection. Know which side of that
  line your excludes are on.
- `--delete-before`, `--delete-during` (the
  default), and `--delete-after` choose *when*
  deletions happen within the run. `--delete-before`
  frees destination space before new files arrive —
  the pick when the disk is tight. `--delete-after`
  holds the old tree together until the new files
  are all in place — the pick when a half-updated
  tree is worse than a stale one.
- Deleting is permanent. rsync has no trash can and
  no undo. The closest thing to an undo is the
  previous chapter's habit — rehearsing — or the
  backup chapter's: keeping snapshots so that a
  bad mirror run is an inconvenience, not a loss.
