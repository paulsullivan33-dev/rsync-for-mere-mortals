# rsync for Mere Mortals

**rsync** is the standard tool for making one
directory tree match another — on the same disk, or
across a network. It is not a plain copier. A copier
sends everything, every time; rsync works out what
actually changed and sends only that. A second sync
of a large tree usually moves almost nothing.

That one idea — *synchronise, don't copy* — explains
both its speed and its dangers. A tool that makes
trees match will happily delete files to make them
match, if you ask it to. This guide teaches the
habits that keep that power pointed the right way:
dry runs before deletions, itemised output you can
actually read, and snapshot backups that cost
almost no disk.

Every command in this guide was run for real
(rsync 3.2.7) against throwaway trees in a lab —
including the mistakes: the trailing-slash slip, a
deletion caught by a dry run, a transfer interrupted
mid-file and resumed, and a daemon that refused to
serve until its permissions made sense. The few
things that genuinely could not be run there are
marked **(documented)** wherever they appear.

It assumes you use a terminal and know what files,
permissions, and a shell prompt are. Nothing here
needs more than one ordinary machine; the network
chapters run over the loopback address, which works
on any machine, connected or not.

## What this guide covers

- [**What rsync is**](what-rsync-is.md) — a
  synchroniser, not a copier; the delta idea; the
  three ways it moves files
- [**Your first sync**](your-first-sync.md) — the
  command's anatomy, and the trailing slash that
  decides where everything lands
- [**Archive mode and friends**](archive-mode.md) —
  what `-a` really switches on, and what it
  deliberately leaves out
- [**Dry runs and reading changes**](dry-runs-and-itemize.md) —
  `--dry-run` as a way of life, and decoding
  `--itemize-changes`
- [**Deleting, carefully**](deleting-carefully.md) —
  `--delete` and exactly when it bites, plus the
  safety nets
- [**Including and excluding**](including-and-excluding.md) —
  patterns, anchoring, and list files
- [**How rsync decides what to send**](what-gets-sent.md) —
  the quick check, its blind spot, `--checksum`,
  and resuming an interrupted transfer
- [**rsync over the network**](over-the-network.md) —
  ssh transport, the daemon mode, compression and
  bandwidth limits, all measured
- [**A worked example**](worked-example.md) — one
  tree through its whole life
- [**rsync as a backup engine**](backup-engine.md) —
  hardlink snapshots with `--link-dest`, and what
  rsync is not
- [**Troubleshooting**](troubleshooting.md) —
  symptom → fix, with the real error messages and
  exit codes
- [**Glossary**](glossary.md) — the terms, collected
  in one place

## What it doesn't cover

The rsync daemon as a public service (authentication
setups, `secrets file` management beyond the basics),
the wire protocol itself, and GUI front ends. For
backup *strategy* — what to keep, retention, testing
restores — see the companion guide, *Backups for
Mere Mortals*; this guide covers the rsync mechanics
that such a strategy can be built on.

## How to use this guide

Read the first two chapters, run the worked example,
and you have the everyday tool. The middle chapters
are reference for the day a sync does something you
didn't expect — which, with rsync, is a day that
comes for everyone.

---

## Part of the series

This guide is one of the [For Mere Mortals](https://paulsullivan33-dev.github.io/mere-mortals/) guides: plain-language guides to the tools programmers and makers use.

Related guides:

- [Backups for Mere Mortals](https://paulsullivan33-dev.github.io/backups-for-mere-mortals/)
- [rclone for Mere Mortals](https://paulsullivan33-dev.github.io/rclone-for-mere-mortals/)
- [SSH for Mere Mortals](https://paulsullivan33-dev.github.io/ssh-for-mere-mortals/)

## License

The writing in this guide is licensed under [CC BY 4.0](https://github.com/paulsullivan33-dev/rsync-for-mere-mortals/blob/main/LICENSE). Code examples and lab scripts are licensed under the [MIT License](https://github.com/paulsullivan33-dev/rsync-for-mere-mortals/blob/main/LICENSE-CODE).
