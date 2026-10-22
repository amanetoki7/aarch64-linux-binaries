# Node.js 22 - self-contained aarch64 Linux build

Built from [nxhack/openwrt-node-packages](https://github.com/nxhack/openwrt-node-packages)
(branch `openwrt-25.12`, `CONFIG_NODEJS_22=y`, `CONFIG_NODEJS_ICU_SMALL=y`) with the
OpenWrt 25.12.5 `mediatek/filogic` SDK (`aarch64_cortex-a53`, gcc 14.3.0, musl 1.2.5,
OpenSSL 3.5.x), then repackaged so that it does not depend on the host system at all.

## Layout of the tarball

```
node22/
  ld.so              bundled musl 1.2.5 dynamic loader (the ONLY libc used)
  bin/node           node binary; PT_INTERP patched in place to /opt/node22/ld.so
  bin/npm, bin/npx   symlinks into lib/node_modules/npm
  lib/lib*.so.*      libstdc++ 6, libgcc_s, libatomic, libssl/libcrypto 3, libz, libnghttp2, libcares
  lib/node_modules/npm
```

Because the interpreter path is hard-coded, the tree **must live at `/opt/node22`**.
Run it with `LD_LIBRARY_PATH=/opt/node22/lib` (the wrapper scripts written by
`install.sh` do this). Never export that variable globally on a musl 1.1 system: every
other binary would pick up the bundled 1.2.5 libraries.

## Requirements

- aarch64 (ARMv8.0-A or newer) CPU, 64-bit Linux kernel 4.x or newer, 4 KiB pages
  (16/64 KiB page kernels are untested).
- About 110 MB on disk and 100 MB free RAM to start.
- Not for armv7 / MIPS / x86.

## Install

```sh
cd /tmp
V=22.23.4
B=https://github.com/amanetoki7/aarch64-linux-binaries/raw/main/node/22
wget $B/$V/node-v$V-aarch64-linux-selfcontained.tar.gz $B/$V/SHA256SUMS.tree $B/install.sh
sh install.sh node-v$V-aarch64-linux-selfcontained.tar.gz
```

`install.sh` extracts to `/opt/node22`, verifies `SHA256SUMS.tree`, keeps the previous
tree at `/opt/node22.prev` (carrying over globally installed npm packages), writes the
`/usr/bin/{node,npm,npx}` wrappers and runs a sanity check.

## Known pitfalls (learned the hard way)

- `patchelf --set-interpreter` / `--set-rpath` corrupts this static-pie binary (segfault);
  the interpreter is changed by overwriting the `.interp` bytes in place instead.
- `strip --strip-unneeded` also corrupts it; only `--strip-debug` is applied.
- `/usr/bin/node` must be a wrapper *file*. A symlink to the real binary lets a later
  `cp`/`scp` write through it and truncate the 71 MB binary to a 73-byte script.
- Native npm add-ons need `linux-arm64-musl` prebuilds (or a toolchain); glibc prebuilds
  will not load. ICU is the "small" build (English-only `Intl`).

## Versions

| Version | Date | Notes |
|---|---|---|
| [22.23.4](22.23.4/) | 2026-10-22 | October 21, 2026 security release (7 CVEs) |
| [22.23.3](22.23.3/) | 2026-10-10 | first build; tree recovered from the router (npm updated to 12.2.0 there) |
