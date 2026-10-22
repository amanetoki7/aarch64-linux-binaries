#!/bin/sh
# Install / upgrade the self-contained Node.js 22 runtime into /opt/node22 (aarch64 Linux, any libc).
#
#   sh install.sh node-v22.x.y-aarch64-linux-selfcontained.tar.gz   # from a tarball
#   sh install.sh /tmp/node22.new                                   # from an already extracted tree
#
# - verifies SHA256SUMS.tree (if present next to the tarball / inside the dir) before swapping
# - keeps the previous tree at /opt/node22.prev and carries over globally installed npm packages
# - /usr/bin/{node,npm,npx} are written as wrapper FILES that set LD_LIBRARY_PATH (never symlinks:
#   a symlink to the binary lets a later copy write THROUGH it and destroy the real binary)
set -e
SRC=${1:-$(ls ./node-v22.*-aarch64-linux-selfcontained.tar.gz 2>/dev/null | head -n1)}
[ -n "$SRC" ] && [ -e "$SRC" ] || { echo "usage: $0 <tarball | extracted dir>"; exit 1; }
D=/opt/node22; NEW=/opt/node22.new
rm -rf "$NEW"; mkdir -p "$NEW"
if [ -d "$SRC" ]; then
  cp -a "$SRC/." "$NEW/"
  SUMS="$NEW/SHA256SUMS.tree"
else
  tar xzf "$SRC" -C "$NEW" --strip-components=1
  SUMS="$(cd "$(dirname "$SRC")" && pwd)/SHA256SUMS.tree"
fi
[ -x "$NEW/bin/node" ] && [ "$(wc -c < "$NEW/bin/node")" -gt 50000000 ] || { echo "ERROR: $NEW/bin/node missing or truncated"; exit 1; }
[ -f "$NEW/ld.so" ] && [ -d "$NEW/lib" ] || { echo "ERROR: $NEW/ld.so or lib/ missing"; exit 1; }
if [ -f "$SUMS" ]; then
  (cd "$NEW" && sha256sum -c "$SUMS" >/dev/null) && echo "sha256: OK" || { echo "ERROR: sha256 mismatch"; exit 1; }
else
  echo "warning: SHA256SUMS.tree not found, skipping verification"
fi
rm -f "$NEW/SHA256SUMS.tree"
chmod 755 "$NEW/ld.so" "$NEW/bin/node"
rm -rf /opt/node22.prev
if [ -d "$D" ]; then
  mv "$D" /opt/node22.prev
  # carry over globally installed packages (everything except npm itself) and their bin links
  for p in /opt/node22.prev/lib/node_modules/* /opt/node22.prev/lib/node_modules/@*/*; do
    [ -d "$p" ] || continue
    rel=${p#/opt/node22.prev/lib/node_modules/}
    case "$rel" in npm) continue;; esac
    case "$rel" in @*) case "$rel" in */*) ;; *) continue;; esac;; esac
    if [ ! -e "$NEW/lib/node_modules/$rel" ]; then
      mkdir -p "$(dirname "$NEW/lib/node_modules/$rel")"
      cp -a "$p" "$NEW/lib/node_modules/$rel"
      echo "kept global package: $rel"
    fi
  done
  for l in /opt/node22.prev/bin/*; do
    [ -L "$l" ] || continue
    n=$(basename "$l")
    case "$n" in node|npm|npx) continue;; esac
    [ -e "$NEW/bin/$n" ] || cp -a "$l" "$NEW/bin/$n"
  done
fi
mv "$NEW" "$D"
rm -f /usr/bin/node /usr/bin/npm /usr/bin/npx
printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/node22/lib exec /opt/node22/bin/node "$@"\n' > /usr/bin/node
printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/node22/lib exec /opt/node22/bin/node /opt/node22/lib/node_modules/npm/bin/npm-cli.js "$@"\n' > /usr/bin/npm
printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/node22/lib exec /opt/node22/bin/node /opt/node22/lib/node_modules/npm/bin/npx-cli.js "$@"\n' > /usr/bin/npx
chmod 755 /usr/bin/node /usr/bin/npm /usr/bin/npx
sync
echo "== sanity =="
node -v
node -e 'const v=process.versions;console.log("v8",v.v8,"openssl",v.openssl,process.arch)'
node -e 'console.log("spawn:",require("child_process").execFileSync(process.execPath,["-e","process.stdout.write(\"child-ok\")"]).toString())'
npm -v
sync
echo "INSTALL DONE (node $(node -v)); previous tree kept at /opt/node22.prev (rm -rf it when satisfied)"
