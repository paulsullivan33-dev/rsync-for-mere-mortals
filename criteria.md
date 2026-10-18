# Writing Criteria

Every guide in this repo is written to the same standard. If you're
adding or editing a guide — human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language, never dumbed-down
   concepts. Explain jargon on first use; collect terms in the
   glossary.
2. **No hype.** No marketing adjectives, no "revolutionary," no
   promises about what something will do for the reader.
3. **Honest about limits.** Say what the thing *can't* do. State
   uncertainty instead of smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults, and specs are either
   measured or qualified with "depends on your setup." If it wasn't
   tested, say so.
5. **Checkable.** Commands are meant to be run, with "Check:" blocks
   showing what success looks like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out Windows/Mac/Linux
   differences. Don't assume a GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and points elsewhere for
   the rest. No guide pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after examples,
   symptom → fix. Scannable beats essay.

## Verification notes for this guide

Standard 3 and 4 applied to this guide, specifically:

**Verified by running, on the build machine**
(rsync 3.2.7, protocol version 31, all local work
in a throwaway lab tree; no `--delete` experiment
was ever pointed outside it):

- The trailing slash, both ways, with the resulting
  trees listed: no slash nests the directory inside
  the destination; slash merges its contents.
- Archive mode's fidelity: a 2020 modification time
  preserved to the nanosecond, a 755 script and a
  600 file kept their modes, a symlink arrived as a
  symlink, an empty directory arrived. Hardlinks
  were shown NOT preserved by plain `-a` (two
  inodes) and preserved with `-H` (one inode, link
  count 2).
- `--itemize-changes` codes produced for real:
  newly created (`>f+++++++++`), size change
  (`>f.s.......`), content+time change
  (`>f.st......`), permissions-only (`.f...p.....`),
  time-only (`>f..t......`), and deletion
  (`*deleting`). A file re-timed by 63 milliseconds
  produced no line at all — times are compared to
  the second.
- Deleting: a `--dry-run` listing `*deleting` left
  the target in place; the real run removed it.
  `--backup --backup-dir` preserved the replaced
  edition of a file. `--max-delete=1` against three
  pending deletions deleted one, reported "2
  skipped", and exited with code 25.
- Excludes: an unanchored `cache` pattern excluded
  caches at two depths; the anchored `/cache`
  excluded only the top one while the nested file
  arrived. `--exclude-from` and `--files-from`
  behaved exactly as listed. In the worked example,
  files excluded after already being mirrored
  survived `--delete` (protected) and were removed
  by `--delete-excluded`.
- The quick check's blind spot: a file replaced
  with same-length different content and a reset
  timestamp was skipped by a plain run (checksums
  proved the copies still differed), then caught
  and fixed by `--checksum`. `--update` protected
  a newer destination file that a plain run then
  overwrote; `--ignore-existing` delivered only the
  missing file.
- The delta: over a daemon connection, a 9-byte
  change inside a 52,428,800-byte file produced
  "Literal data: 7,240 bytes / Matched data:
  52,421,560 bytes". The same edit in a local sync
  sent the whole file (whole-file is the local
  default). An earlier same-second edit was skipped
  entirely by the quick check.
- The daemon: a real `rsync --daemon` on localhost
  listed its module and served pulls. Its first
  pull failed with "Permission denied" and code 23
  because the daemon serves as user `nobody` by
  default and the lab's parent directories (mode
  2770) blocked traversal; adding `uid`/`gid` to
  the module made the identical pull succeed. The
  shipped `examples/rsyncd.conf` is that config,
  comments and lab-shaped paths included (paths
  use `/home/user/...` in place of the lab's own).
- Compression, measured over the daemon: 30 MB of
  zeros crossed as 31,465,059 bytes plain and
  1,077 bytes with `-z`; 30 MB of random data
  crossed as 31,465,058 plain and 31,464,503 with
  `-z`, at roughly a third of the throughput.
  `--bwlimit` was measured locally: 100 MB copied
  in 0.27 s unthrottled, 10.4 s at
  `--bwlimit=10000`.
- `--partial`: a daemon pull of a 240 MB file,
  throttled to 8 MB/s, was interrupted (code 20)
  leaving a 49,020,928-byte partial under its real
  name with an unset timestamp; the resume
  received 202,721,821 bytes instead of the full
  251,658,240 and the result's md5sum matched the
  source.
- `--link-dest` snapshots: the shipped
  `examples/snapshot.sh` (byte-identical to the
  script run) took two snapshots; unchanged files
  shared one inode across both (link count 2),
  the edited file had different inodes, and `du`
  showed 400K for the first snapshot and 8.0K for
  the second.
- ssh transport: a throwaway sshd was installed
  and run on a high port with generated host keys
  and key-only auth; rsync pushes and pulls using
  `host:path` and `-e ssh` were verified in both
  directions. A deliberately wrong `--rsync-path`
  produced the remote "No such file or directory"
  plus code 12 quoted in Troubleshooting. (The lab
  sshd needed `StrictModes no` because the lab's
  home directory is group-writable; that setting
  belongs to the throwaway, not to real servers.)
- Exit codes produced for real: 23 (dangling
  symlink under `-L`), 24 (a source file deleted
  mid-run; the other 39 files transferred), 25
  (`--max-delete`), 20 (interrupted transfer),
  12 (remote rsync unreachable).

**Documented-only (not run), and why:**
- Windows and macOS behaviour, including the
  case-insensitive-filesystem collision: the lab
  runs Linux on a case-sensitive filesystem.
  Windows rsync ports were not installed.
- ACL and xattr preservation (`-A`, `-X`), sparse
  files (`--sparse`), `--append-verify`,
  `--existing`, `--suffix`-style backups, and
  `--modify-window`: described from the manual;
  not needed by any claim the chapters make with
  numbers.
- Daemon `auth users` / secrets-file management:
  explained at the level of "exists, use ssh for
  real security"; no authenticated module was run.
- Scheduling snapshots with cron or systemd
  timers: named as the usual drivers, not taught.
- `--delete-before`/`--delete-after` timing and
  the daemon under systemd on a real server: the
  lab daemon was standalone; timings are described,
  not demonstrated.
