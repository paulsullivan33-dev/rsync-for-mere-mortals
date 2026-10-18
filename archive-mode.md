# Archive Mode and Friends

**Scope:** what `-a` switches on, proof that it
works, and the gaps you have to close on purpose.

## `-a` unpacked

Nearly every rsync command in the wild starts with
`-a`. It is a bundle — shorthand for `-rlptgoD` —
and each letter earns its place:

| Flag | Name | What it does |
|---|---|---|
| `-r` | recursive | descend into subdirectories |
| `-l` | links | copy symlinks as symlinks, not as the files they point to |
| `-p` | perms | preserve permission bits |
| `-t` | times | preserve modification times |
| `-g` | group | preserve group ownership |
| `-o` | owner | preserve owner (only meaningful as root / with privilege) |
| `-D` | devices + specials | preserve device files and fifos (privileged) |

This is the sane default because a synchroniser that
quietly resets times and permissions isn't
synchronising — it's photocopying, and worse, it
breaks the quick check (next chapters) that makes
the next run cheap: preserved times are how rsync
later knows a file is unchanged.

From the lab, the whole bundle at work in one pass
over a tree containing an old file, a private file,
an executable, and a symlink:

```
$ ls -l arch/old.txt arch/secret.txt arch/bin/run.sh
-rwxr-xr-x 1 root root 33 Oct 17 23:47 arch/bin/run.sh
-rw-rw---- 1 root root 20 Jan  2  2020 arch/old.txt
-rw------- 1 root root 31 Oct 17 23:47 arch/secret.txt

$ ls -l arch/link.txt
lrwxrwxrwx 1 root root 10 Oct 17 23:47 arch/link.txt -> README.txt

$ stat -c "%y %n" project/old.txt arch/old.txt
2020-01-02 03:04:00.000000000 +0000 project/old.txt
2020-01-02 03:04:00.000000000 +0000 arch/old.txt
```

The date on `old.txt` is from 2020 on both sides,
the script is still executable, the private file is
still `600`, the link is still a link, and an empty
directory in the source arrived as an empty
directory — plain `cp -r` folklore gets at least
two of those wrong.

**Check:** after any sync where fidelity matters,
`ls -l` a file whose properties you know on both
sides. Times and modes either match or they don't;
there's no partial credit to argue about.

## The working companions

| Option | What it adds |
|---|---|
| `-v` | verbose: list what was transferred (repeat as `-vv` for more) |
| `--progress` | per-file progress and speed during big transfers: `31,457,280 100% 275.23MB/s 0:00:00` |
| `-h` | human-readable sizes in the summaries |
| `-n`, `--dry-run` | show what *would* happen, change nothing — the subject of the next chapter |
| `--stats` | a full report: files transferred, literal vs matched data, totals |

## What `-a` deliberately leaves out

Archive mode is a *curated* default, and three
omissions matter:

- **Hardlinks are not preserved (`-H`).** Two names
  for one file in the source become two separate
  files in the destination — correct contents,
  doubled disk, and a broken relationship if the
  two names were meant to stay the same file:

  ```
  $ ls -li arch/data.bin arch/data-copy.bin   (plain -a)
  5684929 -rw-rw---- 1 root root 18 ... arch/data-copy.bin
  5684930 -rw-rw---- 1 root root 18 ... arch/data.bin

  $ ls -li archH/data.bin archH/data-copy.bin   (with -H)
  5684948 -rw-rw---- 2 root root 18 ... archH/data-copy.bin
  5684948 -rw-rw---- 2 root root 18 ... archH/data.bin
  ```

  Different **inode numbers** (first column) mean
  different files; the same inode, with link count
  2, means one file with two names. Add `-H`
  whenever the source tree uses hardlinks on
  purpose — backup trees and snapshot stores do,
  which is why the backup chapter cares.

- **ACLs (`-A`) and extended attributes (`-X`) are
  not preserved** **(documented)**. If your files
  carry access-control lists or xattrs that matter,
  plain `-a` drops them silently. Add `-A`, `-X`
  (often `-AX`) once you've confirmed your
  destination filesystem supports them.

- **Sparse files** are not recreated sparsely
  without `--sparse` **(documented)** — a mostly
  empty disk image can arrive fat. And files are
  not compared by content: `-a` trusts the quick
  check, like everything else in rsync (chapter:
  How rsync Decides What to Send).

The pattern to remember: `-a` first, then add the
specific letters the tree in front of you needs.
