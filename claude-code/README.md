# Claude Code - native aarch64 musl binary (archive of every npm release)

The official native build published to npm as
[`@anthropic-ai/claude-code-linux-arm64-musl`](https://www.npmjs.com/package/@anthropic-ai/claude-code-linux-arm64-musl)
(`package/claude` inside the tarball), kept here one directory per version so that an
exact version can be pinned on a device that cannot run the official installer or `npm`.

Nothing is rebuilt: `fetch.py` downloads the tarball from the npm registry, extracts the
single binary and records its SHA-256. The binaries are **not** committed (about 221 MB
each, 171 versions, 40 GB in total; GitHub refuses files over 100 MB), only
`<version>/SHA256SUMS` is. Run `fetch.py` to populate the tree and verify it against
the committed checksums.

## Layout

```
claude-code/
  fetch.py             download <version>/claude from npm, write / verify SHA256SUMS
  install.sh           install a binary to /opt/claude-code/<version> and write /usr/bin/claude
  <version>/SHA256SUMS sha256 of that version's `claude` (committed)
  <version>/claude     the binary itself (git-ignored, created by fetch.py)
```

The binary is a Bun-compiled executable: ELF aarch64, dynamically linked against musl
only (`PT_INTERP /lib/ld-musl-aarch64.so.1`, `NEEDED libc.musl-aarch64.so.1`), not
stripped, no other shared libraries.

## Requirements

- aarch64 Linux with a **musl** loader at `/lib/ld-musl-aarch64.so.1`: OpenWrt, Alpine,
  Docker `linux/arm64` Alpine images. On a glibc system (Debian/Ubuntu, Raspberry Pi OS)
  install the `musl` package to get that loader, or run it through the loader bundled in
  the [`node/22`](../node/22/) tree: `/opt/node22/ld.so /opt/claude-code/<version>/claude`.
- About 230 MB on disk per version; the binary is loaded on demand, but expect a few hundred
  MB of RAM while it runs.
- Not for armv7 / MIPS / x86.
- Compatibility with musl 1.1.x (OpenWrt 21.02 and older) is **not verified**: the binary
  is linked against a musl 1.2 toolchain. Only the file layout and checksums in this
  directory were produced on an x86_64 host; nothing here was run on an aarch64 device.

## Fetch

```sh
python3 fetch.py            # all 171 versions (40 GB)
python3 fetch.py 2.1.308    # one version -> 2.1.308/claude
```

Already-present binaries are skipped and re-verified against `SHA256SUMS`; a mismatch is
reported as `[FAIL]`. `--output DIR` writes somewhere other than this directory.

## Install

```sh
cd /tmp
V=2.1.308
B=https://github.com/amanetoki7/aarch64-linux-binaries/raw/main/claude-code
mkdir -p $V && wget -O $V/SHA256SUMS $B/$V/SHA256SUMS && wget $B/install.sh
wget -O $V/claude.tgz https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$V.tgz
tar xzf $V/claude.tgz -C $V && mv $V/package/claude $V/claude && rm -r $V/package $V/claude.tgz
sh install.sh $V/claude
```

(With Python available, `python3 fetch.py $V` replaces the `wget`/`tar` lines.)

`install.sh` verifies `SHA256SUMS`, copies the binary to `/opt/claude-code/<version>/claude`,
writes `/usr/bin/claude` as a wrapper file with `DISABLE_AUTOUPDATER=1` (so the pinned
binary never replaces itself from the network) and runs `claude --version`. Installed
versions stay side by side; `sh install.sh <version>` switches the wrapper to another one
that is already installed, `rm -rf /opt/claude-code/<version>` removes one.

The first run still needs network access and a login (`claude` stores its state in
`~/.claude`); see the [official docs](https://docs.anthropic.com/en/docs/claude-code) for that.

## Versions

Every version published to npm from 2.1.110 (2026-04-15) to 2.1.308 (2026-10-22), 171 in
total; `ls -d */` lists them. npm's `0.0.0` is an empty placeholder (no binary) and is
skipped. Run `python3 fetch.py` again to pick up versions published after this snapshot;
the new `SHA256SUMS` files it writes can then be committed.
