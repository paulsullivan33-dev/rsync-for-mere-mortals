# What rsync Is

**Scope:** the idea underneath every chapter that
follows — and the honest limits of it.

## A synchroniser, not a copier

`cp` copies. Ask it to copy a tree twice and it does
the same work twice, all of it, whether anything
changed or not. rsync instead asks a question first:
*what is different between the source tree and the
destination tree?* Then it moves only the difference.

That makes the second run of an rsync command nearly
free, and it makes rsync the natural engine for
mirrors, deployments, and backups — jobs that are
really the same question asked every day: *make over
there look like over here.*

The vocabulary used throughout the guide:

- The **source** is the tree you read from; the
  **destination** is the tree you make match. rsync
  always flows source → destination.
- A **transfer** is one run of the command. Within
  it, rsync builds a **file list**, compares it
  against the destination, and sends what is needed.

## The delta idea

When a file has changed, rsync does not have to send
the whole file again. For transfers over a network
it uses its rolling-checksum algorithm: the receiver
splits its existing copy into blocks and sends a
small checksum of each; the sender slides the same
window over the new version, finds which blocks it
already has, and transmits only the ones it hasn't —
the **literal data** — plus instructions for
reassembling the rest from blocks on hand (the
**matched data**).

This was measured for the guide, not just described.
A 50 MB file on a server was changed in exactly one
spot (9 bytes), then re-fetched over the network:

```
Total transferred file size: 52,428,800 bytes
Literal data: 7,240 bytes
Matched data: 52,421,560 bytes
```

Of 52 million bytes, about 7 thousand crossed the
network. Everything else was rebuilt from the copy
the receiver already had.

Two honest qualifications, both also measured:

- **Local copies skip the delta.** When source and
  destination are on the same machine, rsync copies
  changed files whole — reading both copies to
  checksum them would cost as much as copying. The
  same 9-byte change in a local sync sent all
  52,428,800 bytes as literal data. (`--no-whole-file`
  exists for the rare local case where the delta is
  worth it.)
- **The delta only runs on files rsync decides are
  changed** — and that decision is cheaper and
  dumber than most people expect. It gets its own
  chapter (How rsync Decides What to Send).

## Three ways to move files

| Mode | Looks like | Typical use |
|---|---|---|
| Local | `rsync -a src/ dst/` | disk to disk, backups on one machine |
| Remote shell | `rsync -a src/ host:dst/` | machine to machine over ssh |
| Daemon | `rsync -a rsync://host/module/ dst/` | published read/write modules, no shell account |

All three share one engine and one set of options;
the chapters move between them freely. The daemon is
the odd one: it is rsync speaking its own protocol
to an `rsync` daemon, with no login shell involved —
and no encryption, a point the network chapter
returns to.

## When rsync isn't the answer

- **Live sharing.** If several programs must work in
  the same files at the same time, that's a network
  share (Samba/NFS), not a sync. rsync makes copies
  that converge; it does not keep them in step
  second by second.
- **Two-way sync.** rsync is one-directional. Edits
  made on both sides need a tool built for that
  (Syncthing, Unison), or a human deciding which
  side wins.
- **A backup *strategy*.** rsync is the finest
  backup *engine* most people will ever need, but
  an engine is not a plan: retention, rotation, and
  restore testing live in *Backups for Mere
  Mortals*. The backup chapter here shows the
  mechanics — snapshots with `--link-dest` — that
  such a plan can stand on.
