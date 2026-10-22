#!/bin/sh
# Install / switch the Claude Code native binary (linux-arm64-musl) into /opt/claude-code/<version>.
#
#   sh install.sh 2.1.308/claude          # from a downloaded binary (fetch.py layout: <version>/claude)
#   sh install.sh /tmp/claude 2.1.308     # from any file; give the version explicitly
#   sh install.sh 2.1.308                 # switch /usr/bin/claude to an already installed version
#
# - verifies <version>/SHA256SUMS (if present next to the binary) before installing
# - every version is kept under /opt/claude-code/<version>/claude; switch back by re-running with
#   the old version, remove old ones with rm -rf /opt/claude-code/<version>
# - /usr/bin/claude is written as a wrapper FILE (never a symlink: a symlink to the binary lets a
#   later copy write THROUGH it and destroy the real binary). It sets DISABLE_AUTOUPDATER=1 so the
#   pinned binary does not try to replace itself from the network.
set -e
D=/opt/claude-code
SRC=$1; VER=$2
[ -n "$SRC" ] || { echo "usage: $0 <binary> [version] | $0 <installed version>"; exit 1; }

if [ ! -e "$SRC" ] && [ -x "$D/$SRC/claude" ]; then
  VER=$SRC                                   # switch only
else
  [ -f "$SRC" ] || { echo "ERROR: $SRC is not a file and not an installed version"; exit 1; }
  SRCDIR=$(cd "$(dirname "$SRC")" && pwd)
  [ -n "$VER" ] || VER=$(basename "$SRCDIR")  # fetch.py layout: <version>/claude
  case "$VER" in [0-9]*.[0-9]*.[0-9]*) ;; *) echo "ERROR: cannot tell the version from '$SRCDIR'; pass it as 2nd argument"; exit 1;; esac
  [ "$(wc -c < "$SRC")" -gt 100000000 ] || { echo "ERROR: $SRC looks truncated"; exit 1; }
  if [ -f "$SRCDIR/SHA256SUMS" ]; then
    (cd "$SRCDIR" && sha256sum -c SHA256SUMS >/dev/null) && echo "sha256: OK" || { echo "ERROR: sha256 mismatch"; exit 1; }
  else
    echo "warning: SHA256SUMS not found next to $SRC, skipping verification"
  fi
  [ -e /lib/ld-musl-aarch64.so.1 ] || echo "warning: /lib/ld-musl-aarch64.so.1 not found; this binary needs musl (see README)"
  NEW=$D/$VER.new
  rm -rf "$NEW"; mkdir -p "$NEW"
  cp "$SRC" "$NEW/claude"; chmod 755 "$NEW/claude"; sync
  rm -rf "$D/$VER"; mv "$NEW" "$D/$VER"
fi

rm -f /usr/bin/claude
printf '#!/bin/sh\nDISABLE_AUTOUPDATER=1 exec %s/%s/claude "$@"\n' "$D" "$VER" > /usr/bin/claude
chmod 755 /usr/bin/claude
sync
echo "== sanity =="
claude --version
echo "INSTALL DONE (claude $VER at $D/$VER/claude); other versions: $(ls "$D" | grep -v "^$VER\$" | tr '\n' ' ')"
