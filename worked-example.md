# A Worked Example

One tree through its whole life, with the real
output at each step. The tree is a small studio
folder — raw photos, exports, notes, and a scratch
directory — being mirrored to `studio-mirror/`.

## Step 1: the first sync

```
$ rsync -av --itemize-changes studio/ studio-mirror/
sending incremental file list
created directory studio-mirror
cd+++++++++ ./
>f+++++++++ notes.txt
cd+++++++++ exports/
>f+++++++++ exports/contact.txt
>f+++++++++ exports/img01-web.jpg
cd+++++++++ raw/
>f+++++++++ raw/img01.jpg
>f+++++++++ raw/img02.jpg
>f+++++++++ raw/img03.jpg
cd+++++++++ scratch/
>f+++++++++ scratch/edit-state.tmp
>f+++++++++ scratch/preview.cache

sent 210,796 bytes  received 227 bytes  422,046.00 bytes/sec
total size is 210,082  speedup is 1.00
```

Every line carries the `+++++++++` of a new item;
directories introduce themselves as `cd` (created
directory). Sent ≈ total size: a first sync is a
copy, as it must be.

## Step 2: life happens, then a rehearsed mirror

The notes are edited, a fourth photo arrives, and
the contact sheet is deleted from the source. The
mirror command — rehearsed first, per the deleting
chapter's rule:

```
$ rsync -av --delete --dry-run --itemize-changes studio/ studio-mirror/
sending incremental file list
>f.st...... notes.txt
*deleting   exports/contact.txt
.d..t...... exports/
.d..t...... raw/
>f+++++++++ raw/img04.jpg
...
total size is 270,075  speedup is 641.51 (DRY RUN)
```

Five lines, all expected: one edit (`s`ize and
`t`ime), one deletion, one arrival, and two
directory lines noting their times changed because
their contents did. The real run that followed
printed the *same five lines* and a live footer —
the rehearsal told the truth:

```
sent 60,496 bytes  received 101 bytes  121,194.00 bytes/sec
total size is 270,075  speedup is 4.46
```

270 KB of tree, 60 KB moved — the new photo — and
the rest was comparison.

## Step 3: the scratch directory retires

Scratch files shouldn't be mirrored at all. Add the
exclude and re-run the mirror:

```
$ rsync -av --delete --itemize-changes --exclude='scratch/' studio/ studio-mirror/
sending incremental file list

$ ls studio-mirror/scratch/   (still there)
edit-state.tmp
preview.cache
```

Two lessons in one empty listing. First, the
exclude works: nothing in `scratch/` is considered
any more. Second — the classic surprise — the
already-mirrored scratch files **survived**
`--delete`. Excluded files are *protected* from
deletion, precisely so that adding an exclude can't
wipe a destination by accident. Removing them is a
separate, deliberate act:

```
$ rsync -av --delete --delete-excluded --itemize-changes --exclude='scratch/' studio/ studio-mirror/
sending incremental file list
*deleting   scratch/preview.cache
*deleting   scratch/edit-state.tmp
*deleting   scratch/

$ ls studio-mirror/
exports  notes.txt  raw
```

`--delete-excluded` lifts the protection for
exactly the excluded things. Treat it like
`--delete` itself: dry-run it first.

## Step 4: freeze it as a snapshot

The mirror is current; now make it *history*. The
snapshot script from `examples/` (next chapter
explains the machinery):

```
$ ./snapshot.sh studio studio-backups
snapshot: /home/.../studio-backups/2026-10-17_235623
```

The studio now has both a mirror (kept current by
steps like 2–3) and a frozen snapshot (kept forever
by doing nothing). That pairing — one tree that
tracks the present, snapshots that keep the past —
is the whole backup pattern of the next chapter,
and it is built from nothing but the commands in
this one.
