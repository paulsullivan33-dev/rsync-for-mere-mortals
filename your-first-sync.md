# Your First Sync

**Scope:** the shape of the command, and the one
punctuation mark that decides where your files land.

## The anatomy

```
rsync -av project/ backup-project/
```

| Piece | Meaning |
|---|---|
| `rsync` | the program |
| `-av` | options (here: archive mode, verbose — chapter 3 unpacks both) |
| `project/` | the source |
| `backup-project/` | the destination |

rsync creates the destination directory if it
doesn't exist, and prints what it did:

```
sending incremental file list
created directory backup-project
./
README.txt
notes/
notes/todo.txt
...
sent 9,504 bytes  received 306 bytes  19,620.00 bytes/sec
total size is 8,473  speedup is 0.86
```

Read the footer once and you'll read it forever:
**sent/received** are the bytes that crossed between
rsync's two halves during this run, and **total
size** is the size of the whole file list. When the
two numbers are close, you copied; when sent is a
small fraction of total size, you synchronised.

Run the same command again immediately. The list is
empty and almost nothing moves. That second run is
the whole point of the tool.

## The trailing slash

This is the single most common rsync mistake, and
it is one character:

- `rsync -av project backup-project/` — **no slash
  on the source** — copies the directory *itself*
  into the destination.
- `rsync -av project/ backup-project/` — **slash on
  the source** — copies the directory's *contents*
  into the destination.

Run both ways against empty destinations, then look
at where things landed:

```
$ find noslash slash | sort
noslash
noslash/project
noslash/project/README.txt
noslash/project/notes
noslash/project/notes/todo.txt
...
slash
slash/README.txt
slash/notes
slash/notes/todo.txt
```

Neither is wrong; they answer different questions.
"Put this folder over there" wants no slash. "Make
that folder's contents match this folder's contents"
— the mirror, the backup, the deployment — wants
the slash. Most of this guide uses the slash form,
because most real rsync jobs are mirrors.

Two neighbouring facts worth fixing in memory now:

- A slash on the **destination** changes nothing.
  `dst` and `dst/` mean the same thing to rsync.
  Only the source slash matters.
- The verbose listing tells you which form you used,
  if you read it: with no slash, the first line is
  `project/` and every path starts with `project/`;
  with the slash, the first line is `./` and paths
  are bare. **Check:** run both forms with `--dry-run`
  (next-but-one chapter) whenever a destination
  matters, and read that first line before letting
  the real run go.

## One file, and files from elsewhere

A single file works the same way:
`rsync -av notes.txt archive/` puts the file *in*
`archive/`; `rsync -av notes.txt archive/renamed.txt`
renames it on the way. And a source or destination
on another machine is written `host:path` — the
network chapter covers it; nothing about the local
habits changes.

**Scope note:** rsync's behaviour is the same on
Linux, macOS, and the BSDs; Windows users usually
meet it through WSL or a port **(documented)**.
Paths with spaces need the usual shell quoting —
rsync gets whatever your shell hands it.
