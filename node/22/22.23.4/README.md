# Node.js v22.23.4 (aarch64, self-contained)

- Built 2026-10-22 with the OpenWrt 25.12.5 filogic SDK (gcc 14.3.0, musl 1.2.5) from
  nxhack/openwrt-node-packages `openwrt-25.12` at the "October 21, 2026 Security Releases"
  commit (node 22.23.4, npm 10.9.9, OpenSSL 3.5.7, ICU small).
- `bin/node` sha256 `c687a46f4af9de488a203c80dab23652e2f3296b062601920b91a952fc92184a`.
- Verified on a GL-MT6000 (OpenWrt 21.02, kernel 5.4) via `../install.sh` from this tarball:
  `node -v` = v22.23.4, V8 12.4.254.21, OpenSSL 3.5.7, child_process spawn, npm 10.9.9,
  HTTPS/TLS, 5/5 consecutive starts, global packages carried over from the previous tree.

Files: `node-v22.23.4-aarch64-linux-selfcontained.tar.gz` (tree, about 28 MB), `SHA256SUMS`
(tarball), `SHA256SUMS.tree` (files inside the tree). Install with `../install.sh`.
