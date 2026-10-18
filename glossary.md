# Glossary

**Archive mode** — `-a`, the bundle `-rlptgoD`:
recursive, links, permissions, times, group,
owner, devices/specials. The sane default.

**Daemon** — rsync running as a server, serving
named modules over its own protocol (port 873 by
default), without a shell account or encryption.

**Delta transfer** — sending only the changed
blocks of a file, found by comparing rolling
checksums. Used over the network; local copies
default to whole-file instead.

**Dry run** — `-n` / `--dry-run`: the full
comparison and listing, with nothing transferred,
changed, or deleted.

**Exclude / include** — filter rules
(`--exclude`, `--include`) that keep paths out of
(or rescue paths into) the transfer, matched in
order, first match wins.

**File list** — the inventory rsync builds of the
source before comparing it with the destination.

**Hardlink** — a second (or third) name for the
same file data: same inode, shared content.
Preserved across a sync only with `-H`; created
on purpose by `--link-dest`.

**Inode** — the filesystem's identifier for a
file's data. Two names with the same inode are
the same file; `ls -li` shows it.

**Itemize changes** — `--itemize-changes`, the
11-character code prefixed to each listing line
describing what changed and why.

**Link-dest** — `--link-dest=DIR`: compare against
a previous tree and hardlink unchanged files from
it into the new one. The snapshot mechanism.

**Literal data** — bytes actually sent for a file
because the receiver didn't already hold matching
blocks. Its counterpart is **matched data**:
bytes rebuilt from the receiver's existing copy.

**Module** — a directory plus rules (path,
read-only, who may connect) that an rsync daemon
serves under a name.

**Partial** — `--partial`: keep the transferred
portion of an interrupted file so the next run
resumes from it instead of starting over.

**Quick check** — rsync's default change test:
same size *and* same modification time means
unchanged, contents never read.

**Rolling checksum** — the sliding-window checksum
that lets the sender find matching blocks in a
changed file even after insertions shift
everything downstream.

**Snapshot (rsync sense)** — a complete copy of a
tree at a moment, built with `--link-dest` so
unchanged files are hardlinks to the previous
snapshot and cost no new disk.

**Speedup** — the summary's ratio of total size to
bytes actually moved; around 1 for a first copy,
large when a run mostly compared.

**Trailing slash** — the `/` on the source path
that switches rsync between "copy this directory"
(no slash) and "copy its contents" (slash).
