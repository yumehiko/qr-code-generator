#!/bin/bash
set -euo pipefail

case "$(basename "$0")" in
hdiutil)
  case "$1" in
  verify) exit 0 ;;
  attach)
    mount_point=""
    while [ "$#" -gt 0 ]; do
      if [ "$1" = "-mountpoint" ]; then mount_point="$2"; shift 2; continue; fi
      shift
    done
    [ -n "$mount_point" ]
    mkdir -p "$mount_point/QR Code Generator.app"
    printf 'mount:%s\n' "$mount_point" >> "$MOCK_LOG"
    printf '/dev/disk77\tGUID_partition_scheme\n/dev/disk77s1\tApple_APFS\t%s\n' "$mount_point"
    ;;
  detach)
    mount_point="$(awk -F: '/^mount:/ { print substr($0, 7); exit }' "$MOCK_LOG")"
    rmdir "$mount_point/QR Code Generator.app"
    rmdir "$mount_point"
    printf 'detach:%s\n' "$2" >> "$MOCK_LOG"
    ;;
  *) exit 1 ;;
  esac
  ;;
xcrun|spctl|codesign) exit 0 ;;
*) exit 1 ;;
esac
