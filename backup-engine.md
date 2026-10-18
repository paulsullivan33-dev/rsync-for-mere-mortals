# rsync as a Backup Engine

**Scope:** the snapshot pattern — a full, browsable
backup every run, at close to the cost of an
incremental — and an honest list of what rsync
does not do for you.

This chapter is the mechanics. The strategy —
what deserves backing up, how many snapshots to
keep, testing restores — is *Backups for Mere
Mortals*; rsync is the engine that strategy can
run on, and this is how the engine works.

## The problem with a mirror

A mirror (previous chapters) keeps the destination
equal to the source *now*. Delete a file by
accident, mirror that evening, and the backup has
helpfully deleted it too. Corrupt a file and the
corruption is faithfully mirrored. A backup needs
the past, not just the present.

The naive past — a full copy every day — costs a
full copy every day. rsync's answer is
`--link-dest`.

## `--link-dest`: snapshots that share

```
rsync -a --link-dest=<previous snapshot> source/ <new snapshot>/
```

While syncing, rsync compares each file against
the same file in the *previous* snapshot. If it's
unchanged, it doesn't copy it — it creates a
**hardlink** in the new snapshot to the old file.
Both snapshots then name the same inode: one body
of data, two directory entries, near-zero extra
disk. Changed files are copied fresh, as their own.

From the lab — a small library, snapshotted, then
one file edited and one added, and snapshotted
again:

```
$ ls -li backups/2026-10-17_235122/reading.txt backups/2026-10-17_235124/reading.txt
5685588 -rw-rw---- 2 root root 13 ... backups/2026-10-17_235122/reading.txt
5685588 -rw-rw---- 2 root root 13 ... backups/2026-10-17_235124/reading.txt

$ ls -li backups/2026-10-17_235122/catalogue.txt backups/2026-10-17_235124/catalogue.txt
5685587 -rw-rw---- 1 root root 25 ... backups/2026-10-17_235122/catalogue.txt
5685595 -rw-rw---- 1 root root 45 ... backups/2026-10-17_235124/catalogue.txt
```

The unchanged file: same inode (5685588), link
count 2. The edited file: different inodes, one
copy per snapshot — exactly the semantics you
want. And the disk tells the same story:

```
$ du -sh backups/2026-10-17_235122 backups/2026-10-17_235124
400K    backups/2026-10-17_235122
8.0K    backups/2026-10-17_235124
```

Each snapshot *reads* as a complete tree of about
400 KB; the second one costs 8 KB of real disk.
Deleting an old snapshot frees only the files no
other snapshot shares — the survivors keep their
data until the last snapshot holding them goes.

## The script

`examples/snapshot.sh` is the pattern as a tool —
the exact script run for this chapter. It keeps a
`latest` symlink so each run can find its
predecessor for `--link-dest`:

```bash
#!/usr/bin/env bash
set -euo pipefail

src=$1
root=$2
stamp=$(date +%Y-%m-%d_%H%M%S)

mkdir -p "$root"
root=$(cd "$root" && pwd)   # --link-dest wants an unambiguous path

link_opt=()
if [ -L "$root/latest" ]; then
    link_opt=(--link-dest="$root/latest")
fi

rsync -a "${link_opt[@]}" "$src"/ "$root/$stamp/"
ln -sfn "$stamp" "$root/latest"
echo "snapshot: $root/$stamp"
```

Used as `./snapshot.sh library backups`, it is the
worked example's step 4 with a memory. Note what
the script does *not* pass: `--delete`. A snapshot
destination starts empty; there is nothing to
delete, and adding it would only invite accidents.

## What rsync is not

Stated plainly, because these surprises have names
and dates in other people's post-mortems:

- **No versioning database.** rsync keeps no history
  of its own. The snapshots *are* the history — a
  plain tree you can browse with `ls`. That's a
  feature until you want per-file history, search,
  or deduplication across unrelated trees; then
  you want a real backup tool (restic, BorgBackup —
  covered in the Backups guide).
- **Deletions and corruption propagate to mirrors.**
  Snapshots quarantine the damage to "after the
  last good snapshot"; a plain mirror has no such
  mercy. Never let a mirror be your only copy.
- **No scheduling.** rsync runs when something runs
  it. cron and systemd timers are the usual
  drivers; they are named here, not taught
  **(documented)**.
- **No encryption or integrity archive.** Snapshots
  are live files on a filesystem; bit-rot and
  ransomware reach them as easily as the originals.
  Off-site and offline copies remain a strategy
  question, not an rsync flag.
- **The same filesystem, please.** Hardlinks only
  exist within one filesystem, so all snapshots in
  a set must live on the same volume — the script's
  single backup root enforces this by construction.

Used with its eyes open, though: a snapshot set is
a backup you can *inspect*, restore from with
`cp`, and reason about with `du`. Mortals have
retired on less.
