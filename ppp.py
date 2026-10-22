#!/usr/bin/env python3

import argparse
import json
import os
import shutil
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

PACKAGE = "@anthropic-ai/claude-code-linux-arm64-musl"
REGISTRY_URL = f"https://registry.npmjs.org/{PACKAGE}"
TIMEOUT = 120


def open_url(url):
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "claude-binary-archiver/1.0"},
    )
    return urllib.request.urlopen(request, timeout=TIMEOUT)


def get_metadata():
    with open_url(REGISTRY_URL) as response:
        return json.load(response)


def extract_binary(version, metadata, output_dir):
    destination = output_dir / version / "claude"

    if destination.is_file() and destination.stat().st_size > 0:
        print(f"[SKIP] {version}: {destination}")
        return

    tarball_url = metadata["dist"]["tarball"]
    print(f"[GET]  {version}: {tarball_url}", flush=True)

    destination.parent.mkdir(parents=True, exist_ok=True)

    # 一時ファイルは保存先と同じファイルシステムに作成する。
    with tempfile.TemporaryDirectory(
        prefix=".download-",
        dir=destination.parent,
    ) as temp_dir:
        temp_dir = Path(temp_dir)
        archive_path = temp_dir / "package.tgz"
        binary_path = temp_dir / "claude"

        with open_url(tarball_url) as response:
            with archive_path.open("wb") as output:
                shutil.copyfileobj(response, output)

        with tarfile.open(archive_path, mode="r:gz") as archive:
            member = archive.getmember("package/claude")

            if not member.isfile():
                raise ValueError("package/claude is not a regular file")

            source = archive.extractfile(member)
            if source is None:
                raise ValueError("Cannot read package/claude")

            # extractall() は使わず、対象ファイルの内容だけを書き出す。
            with source, binary_path.open("wb") as output:
                shutil.copyfileobj(source, output)

        if binary_path.stat().st_size == 0:
            raise ValueError("Extracted binary is empty")

        binary_path.chmod(0o755)
        os.replace(binary_path, destination)

    print(f"[OK]   {version}: {destination}", flush=True)


def main():
    parser = argparse.ArgumentParser(
        description="Claude Code ARM64 musl binariesをバージョン別に保存します。"
    )
    parser.add_argument(
        "versions",
        nargs="*",
        help="取得するバージョン。省略すると公開されている全バージョン。",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("./claude-code"),
        help="保存先ディレクトリ（既定: ./claude-code）",
    )
    args = parser.parse_args()

    metadata = get_metadata()
    published_versions = metadata["versions"]

    versions = (
        list(dict.fromkeys(args.versions))
        if args.versions
        else list(published_versions)
    )

    unknown = [v for v in versions if v not in published_versions]
    if unknown:
        parser.error(f"公開されていないバージョン: {', '.join(unknown)}")

    print(f"対象: {len(versions)} バージョン", flush=True)
    failures = []

    for version in versions:
        try:
            extract_binary(version, published_versions[version], args.output)
        except Exception as error:
            failures.append(version)
            print(f"[FAIL] {version}: {error}", file=sys.stderr, flush=True)

    print(f"\n完了: {len(versions) - len(failures)} / {len(versions)}")

    if failures:
        print(f"失敗: {', '.join(failures)}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
