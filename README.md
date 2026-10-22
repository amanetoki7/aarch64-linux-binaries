# aarch64-linux-binaries

Self-contained binaries for 64-bit ARM (aarch64) Linux, built for devices whose stock
firmware is too old to get them from a package feed (originally a GL.iNet GL-MT6000
running OpenWrt 21.02 / musl 1.1.24).

Each tree bundles its own musl loader and every shared library it needs, so it runs on
any aarch64 Linux regardless of the host libc (OpenWrt, Alpine, Debian/Ubuntu,
Raspberry Pi OS 64-bit, Docker `linux/arm64`, ...). The only dependency is the kernel.

| Path | Contents |
|---|---|
| [`node/22/`](node/22/) | Node.js 22.x (nxhack/openwrt-node-packages, OpenWrt 25.12 SDK, gcc 14.3 / musl 1.2.5 / OpenSSL 3) |
| [`claude-code/`](claude-code/) | Claude Code native binary, every npm release of `@anthropic-ai/claude-code-linux-arm64-musl` (checksums + fetch/install scripts; binaries are downloaded from npm, not stored here) |

See the README in each directory for build details, checksums and install steps.
