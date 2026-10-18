# How rsync Decides What to Send

**Scope:** the cheap comparison that makes rsync
fast, the hole in it, and the options that change
the decision.

## The quick check

For each file, rsync compares two facts on both
sides: **size** and **modification time**. If both
match, the file is declared unchanged and skipped —
its contents are never read. If either differs,
the file is a candidate and gets transferred (by
delta over the network, whole-file locally).

This is why rsync is fast, and why `-t` in archive
mode matters: without preserved timestamps at the
destination, every file looks "different" forever
and nothing is ever skipped.

## The blind spot

Size and time are a proxy for content, and a proxy
can be fooled. In the lab, one file's contents were
replaced with different words of exactly the same
length, and its timestamp was reset to match the
copy:

```
$ ls -l qc-src/f.txt qc-dst/f.txt
-rw-rw---- 1 root root 11 ... qc-dst/f.txt
-rw-rw---- 1 root root 11 ... qc-src/f.txt
$ md5sum qc-src/f.txt qc-dst/f.txt
049d01c97ed794d3c122048e56e894d5  qc-src/f.txt
86d48f739677a6bc11751a9a3fd4a0d1  qc-dst/f.txt

$ rsync -av qc-src/ qc-dst/   (quick check: same size, same time — skipped)
sending incremental file list

$ md5sum qc-src/f.txt qc-dst/f.txt   (still different!)
049d01c97ed794d3c122048e56e894d5  qc-src/f.txt
86d48f739677a6bc11751a9a3fd4a0d1  qc-dst/f.txt
```

The checksums prove the files differ; rsync's run
moved nothing, correctly by its rules. When does
this happen in real life? Tools that restore files
with their original timestamps, files edited by
something that resets times, exports and checkouts
that preserve both size class and date. Rare — but
silent when it happens.

## `--checksum`: paying for certainty

`--checksum` (or `-c`) replaces the time half of
the quick check with a content checksum, on both
sides, for every file:

```
$ rsync -av --checksum qc-src/ qc-dst/
sending incremental file list
f.txt

$ md5sum qc-src/f.txt qc-dst/f.txt
049d01c97ed794d3c122048e56e894d5  qc-src/f.txt
049d01c97ed794d3c122048e56e894d5  qc-dst/f.txt
```

Caught, transferred, matched. The cost is real:
every file is read in full on both ends before the
run can start deciding, which on a large tree can
take longer than the transfer it saves. Use it for
audits and for trees you have a specific reason to
distrust — not as a default.

Two related switches, from the lab:

- **`--update` (`-u`)** skips a file when the
  *destination's* copy is newer than the source's.
  With a destination file edited locally (dated
  June) and a source file dated January, the run
  transferred nothing and the local edit survived;
  without `--update`, the differing size made plain
  rsync overwrite the newer edit with the older
  source. It is the polite option for two places
  that both change files — with the obvious limit
  that "newer wins" is a clock comparison, not a
  merge.
- **`--ignore-existing`** never updates a file that
  already exists at the destination, but still
  delivers files that are missing there. In the
  lab it brought the new file across and left a
  same-named file's destination wording untouched,
  word for word. (Its mirror image,
  `--existing`, sends only files that already
  exist **(documented)**.)

## Coming back from an interruption: `--partial`

Kill a long transfer and the destination keeps a
hidden temporary file; the next run starts the
file over. `--partial` changes the deal: what
arrived is kept and, next run, used as the basis
for the delta — only the remainder crosses.

From the lab: a 240 MB file pulled at a throttled
8 MB/s, interrupted (Ctrl-C, in effect) after six
seconds:

```
rsync error: received SIGINT, SIGTERM, or SIGHUP (code 20) at rsync.c(716) [generator=3.2.7]

$ ls -la partial-dest/
-rw-rw---- 1 root root 49020928 Jan  1  1970 blob.bin
```

The partial is recognisable: real name, nearly
49 MB of the eventual 240 MB, and a nonsense 1970
timestamp, because rsync only stamps times onto a
file when the file completes. The resume:

```
$ rsync -av --partial rsync://127.0.0.1:8873/demo/blob.bin partial-dest/
receiving incremental file list
blob.bin

sent 49,064 bytes  received 202,721,821 bytes  45,060,196.67 bytes/sec
total size is 251,658,240  speedup is 1.24
```

Received 202 MB, not 251 MB — the 49 MB already on
disk was checked against the source's blocks and
kept. `md5sum` afterwards matched on both sides.
`--partial-dir=.rsync-partial` **(documented)**
keeps partials in a named subfolder instead, which
suits destinations other tools scan (they'd
otherwise meet a half-written file wearing its
final name).
