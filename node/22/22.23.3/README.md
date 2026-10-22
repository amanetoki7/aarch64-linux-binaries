# Node.js v22.23.3 (aarch64, self-contained)

- Built 2026-10-10 with the OpenWrt 25.12.5 filogic SDK (gcc 14.3.0, musl 1.2.5) from
  nxhack/openwrt-node-packages `openwrt-25.12` (node 22.23.3; npm 10.9.x at build time).
- This tree was recovered from the router it was deployed on; the bundled npm had been
  upgraded there to **12.2.0**, which is what the tarball contains. Everything else
  (node binary, loader, libraries) is byte-identical to the original build
  (`bin/node` sha256 `fceacfa58ac37be0b4725bfbc33088026b5ad83eedf26181a4b12b7160803fba`).
- Verified on a GL-MT6000 (OpenWrt 21.02, kernel 5.4): `node -v`, V8 12.4, OpenSSL 3.5.7,
  child_process spawn, npm, HTTPS/TLS.

Files: `node-v22.23.3-aarch64-linux-selfcontained.tar.gz` (tree, about 34 MB), `SHA256SUMS`
(tarball), `SHA256SUMS.tree` (files inside the tree). Install with `../install.sh`.
