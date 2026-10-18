# rsync Over the Network

**Scope:** the two network transports — a remote
shell (usually ssh) and the rsync daemon — plus
compression and bandwidth limits, with the numbers
measured rather than assumed.

Everything in this chapter was run over the
loopback address, 127.0.0.1, to a throwaway ssh
server and a throwaway rsync daemon set up in the
lab. Loopback exercises the same code paths as a
real network; only the speeds are flattering.

## The remote-shell form: `host:path`

A single colon in the source or destination makes
it remote:

```
rsync -av project/ user@host:/srv/project/
rsync -av user@host:/srv/project/ project/    (pull)
```

rsync starts a copy of itself on the far side by
way of a remote shell — ssh by default — and the
two copies speak the rsync protocol through the
encrypted tunnel. In the lab, against the lab's
own sshd on a nonstandard port (`-e` names the
shell command, including its options):

```
$ rsync -av -e 'ssh -p 2222 -i <lab key>' ssh-src/ root@127.0.0.1:/home/.../ssh-dst/
sending incremental file list
./
cargo.txt
manifest.txt

sent 231 bytes  received 57 bytes  576.00 bytes/sec
total size is 29  speedup is 0.10
```

Push and pull both verified, contents intact.
Habits that keep this form boring:

- Get plain `ssh user@host` working first, keys
  and all. rsync inherits ssh's authentication
  *and* its failures; if ssh can't log in, rsync
  can't either, and its error will say less.
- Nonstandard ports, identity files, jump hosts:
  all of it is ssh's business, set with `-e 'ssh
  -p PORT -i KEY'` or in `~/.ssh/config`, where a
  `Host` block quietly supplies them to both ssh
  and rsync.
- The far side needs rsync installed too. If it's
  missing, you get the remote shell's complaint
  plus a protocol error — quoted verbatim in the
  Troubleshooting chapter, because the lab produced
  it on purpose.

## The daemon form: `rsync://`

An rsync **daemon** serves named **modules** —
directories with rules — on TCP port 873 (the lab
used 8873). No shell account, no ssh; the client
speaks to the daemon directly:

```
$ rsync rsync://127.0.0.1:8873/
demo            Demo module for the guide lab

$ rsync -av rsync://127.0.0.1:8873/demo/ pulled/
receiving incremental file list
created directory pulled
./
hello.txt
manual.txt
```

Listing a daemon's modules, as above, costs
nothing and is the first diagnostic when a path
is in doubt. The daemon's whole configuration is
one file, `rsyncd.conf` — the lab's is shipped in
`examples/`:

```
[demo]
    path = /home/.../served
    comment = Demo module for the guide lab
    read only = yes
    list = yes
    uid = root
    gid = root
```

Three facts about the daemon, each earned in the
lab:

- **The daemon serves as a user.** Started by root,
  it drops to the user `nobody` for a module unless
  `uid`/`gid` say otherwise. The lab's first pull
  failed — `failed to open ... Permission denied`,
  exit code 23 — because `nobody` couldn't traverse
  the directories above the served tree, even
  though the files themselves were readable.
  Naming `uid = root` for the lab module made the
  identical pull succeed. On a normal system the
  fix is the opposite (serve as an unprivileged
  user, make the paths traversable), but the lesson
  travels: when a daemon module lists fine and then
  refuses the files, suspect the uid and the path
  to the files, in that order.
- **Nothing is encrypted.** The daemon protocol
  has optional per-module password authentication
  (`auth users` with a secrets file
  **(documented)**), but the file contents cross
  in the clear. On a trusted LAN or inside a VPN
  that may be acceptable; over the open internet,
  use the ssh form. This is the daemon's honest
  trade: it is simple and fast because it leaves
  security to the network around it.
- **It's fast and it's public-shaped.** Modules
  are how software mirrors have distributed files
  for decades — anonymous, read-only, and cheap to
  serve.

## `-z`: compression, when it's worth it

`-z` compresses the data in transit. Whether that
helps depends entirely on what the files are made
of — measured on the lab daemon with two 30 MB
files:

| File | Received, no `-z` | Received, with `-z` |
|---|---|---|
| 30 MB of zeros (extreme case) | 31,465,059 bytes | **1,077 bytes** |
| 30 MB of random data (already dense) | 31,465,058 bytes | 31,464,503 bytes |

Random data *is* pre-compressed data, for this
purpose: photographs, video, zip files, and disk
images behave the same way. There, `-z` bought
555 bytes — and cost real speed (the throttled-by-CPU
run finished at about a third of the plain run's
throughput on this machine). Rule of thumb:
compress text, logs, and source trees; skip `-z`
for media and archives.

## `--bwlimit`: being a good neighbour

`--bwlimit=8000` caps the transfer at 8,000 KB/s.
It applies to local copies too in this version:
a 100 MB local copy that took 0.27 s unthrottled
took 10.4 s at `--bwlimit=10000` (measured). Use it
when a sync shares a link — or a disk — with
anything else that matters, and when you need a
long transfer to stay interruptible, as the
`--partial` demonstration in the previous chapter
did.
