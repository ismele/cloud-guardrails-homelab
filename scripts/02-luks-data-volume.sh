#!/usr/bin/env bash
# Encrypt a dedicated data volume with LUKS2 (AES-256-XTS, Argon2id) and mount it.
# WARNING: this ERASES the target device.
# Usage: sudo bash 02-luks-data-volume.sh /dev/xvdb [mountpoint]
set -euo pipefail

DEV="${1:?usage: $0 <device> [mountpoint]}"
MNT="${2:-/srv/data}"
NAME="data_crypt"
KEY="/root/${NAME}.key"

[[ -b "$DEV" ]] || { echo "Not a block device: $DEV"; exit 1; }
ROOT_DISK="/dev/$(lsblk -no PKNAME "$(findmnt -no SOURCE /)")"
[[ "$DEV" != "$ROOT_DISK" ]] || { echo "Refusing: $DEV is the root disk"; exit 1; }
[[ -z "$(lsblk -no MOUNTPOINT "$DEV" | tr -d '[:space:]')" ]] || { echo "Refusing: $DEV has mounted partitions"; exit 1; }

lsblk "$DEV"
read -r -p "ALL DATA on $DEV will be destroyed. Type YES to continue: " ok
[[ "$ok" == "YES" ]] || { echo "Aborted"; exit 1; }

# 512-bit random key file, readable only by root
dd if=/dev/urandom of="$KEY" bs=64 count=1 status=none
chmod 0400 "$KEY"

cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 512 \
  --hash sha256 --pbkdf argon2id --batch-mode "$DEV" "$KEY"

echo "Add an offline recovery passphrase (key slot 1):"
cryptsetup luksAddKey --key-file "$KEY" "$DEV"

cryptsetup open --key-file "$KEY" "$DEV" "$NAME"
mkfs.xfs -q "/dev/mapper/$NAME"
mkdir -p "$MNT"
mount "/dev/mapper/$NAME" "$MNT"

UUID="$(cryptsetup luksUUID "$DEV")"
grep -q "^$NAME " /etc/crypttab 2>/dev/null || echo "$NAME UUID=$UUID $KEY luks" >> /etc/crypttab
grep -q "/dev/mapper/$NAME " /etc/fstab || echo "/dev/mapper/$NAME $MNT xfs defaults,nofail 0 2" >> /etc/fstab

echo "--- verification"
lsblk -f "$DEV"
cryptsetup status "$NAME"
