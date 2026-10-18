# Troubleshooting

**Scope:** the failures rsync actually produces,
in its own words — every message below was
generated in the lab while building this guide.

rsync's exit code is the first diagnostic. Zero is
a clean run; anything else is a specific complaint.
The codes in this chapter: **23** (some files not
transferred), **24** (files vanished mid-run),
**25** (the `--max-delete` limit stopped
deletions), **20** (interrupted by a signal),
**12** (the protocol never got started).

## Symptom → "some files/attrs were not transferred" (code 23)

```
symlink has no referent: "/home/.../err-src/broken.txt"
...
rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1356) [sender=3.2.7]
```

Code 23 is a bucket: *something* in the list
couldn't be transferred, everything else was, and
the lines *above* the summary name the casualties.
The lab produced it with a dangling symlink copied
under `-L` (follow links): there was nothing at
the other end of the link to send. The same code
covers unreadable files (permissions) and, in the
network chapter, a daemon that couldn't open its
own module's files:

```
rsync: [sender] send_files failed to open "hello.txt" (in demo): Permission denied (13)
```

**Fix:** read upward, not the summary. For
permission denials, check the whole path — the
daemon case was a parent directory the daemon's
user couldn't traverse, not the file's own mode.

## Symptom → "some files vanished before they could be transferred" (code 24)

```
file has vanished: "/home/.../vanish-src/f25.bin"
rsync warning: some files vanished before they could be transferred (code 24) at main.c(1356) [sender=3.2.7]
```

The file was there when rsync built its list and
gone when its turn came — deleted, rotated, or
still being written by something else. In the lab
the file was removed mid-run on purpose; the other
39 of 40 files arrived. Code 24 is a *warning*
class: the run completed, and one source was a
moving target.

**Fix:** usually none, or sync a quieter tree —
snapshot the source first (a filesystem snapshot,
or a copy made when the writer is idle) if the
tree is busy. Treat 24 as fatal only if your
scripts must, and know that log directories and
mail spools produce it innocently all the time.

## Symptom → the remote side never starts (code 12)

```
bash: line 1: /nonexistent/rsync: No such file or directory
rsync: connection unexpectedly closed (0 bytes received so far) [sender]
rsync error: error in rsync protocol data stream (code 12) at io.c(232) [sender=3.2.7]
```

Over a remote shell, rsync must run on *both*
ends. The remote shell's own error line — here a
deliberately wrong path — is the real message; the
code-12 line just says the protocol stream died.
The everyday version reads `rsync: command not
found` **(documented phrasing — the shell's, so it
varies)**: rsync isn't installed on the far side,
or isn't on the login shell's PATH.

**Fix:** install rsync remotely, or point
`--rsync-path` at where it lives. Diagnose with
the shell alone: `ssh host 'which rsync'` must
succeed before rsync-over-ssh can.

## Symptom → the run stops dead (code 20)

```
rsync error: received SIGINT, SIGTERM, or SIGHUP (code 20)
```

Somebody interrupted it — Ctrl-C, a closed
terminal, a killed script. Nothing here is
corrupt: completed files are complete,
in-progress files are not (that's the state
`--partial` exists to improve — see How rsync
Decides What to Send). Re-run the same command;
the quick check skips everything already done.

## Symptom → files arrive with wrong owners or modes

Causes, in the order to check them:
`-a` wasn't used (plain `-r` drops times and
permissions by design); the destination filesystem
can't represent them (a FAT stick has no Unix
modes to preserve — the sync "works" and the
metadata silently doesn't **(documented)**); the
copy was made as a different user than the one
that reads it; or the daemon's `uid`/`gid` settings
are doing exactly what they say. `stat` one file on
both sides and compare — the mismatch is always
visible in one look.

## Symptom → the copy works here, fails on a case-insensitive destination

A tree containing both `Readme.txt` and
`README.txt` is legal on Linux and a collision on
default macOS and Windows filesystems: the two
names fight over one destination file, and the
"sync" churns or loses one **(documented — the
lab's filesystem is case-sensitive, so this
couldn't be produced there)**. **Fix:** rename on
the source; no rsync option reconciles names the
destination can't distinguish.

## Symptom → it re-copies everything, every time

The quick check is failing open. Almost always:
timestamps aren't being preserved (no `-t`, so not
using `-a`), or the destination clock/format can't
hold them (some network filesystems round times —
`--modify-window=2` is the documented tolerance
for exactly that **(documented)**). One itemised
dry run shows it: every file listed as changed,
every run. Compare one file's times with `stat`
on both sides; they will not match, and the reason
is one of the two above.
