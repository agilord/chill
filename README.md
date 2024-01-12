`chill` is a command-line backup tool for incremental, offline (cold storage) and encrypted archives:

- `offline/cold storage`: the archived content is meant to be stored on
  disks that are only temporarily attached to a computer

- `incremental`: the tool keeps a local state of the processed files
  and skips the ones that are already stored during the previous sessions.

- `encrypted`: the tool encypts the content on the disk so unauthorized tools
  or persons cannot observe its content.

## Limitations and disclaimers

- *May not work.*
- *May lose data.*
- *May not protect data.*
- Data format is not stable.
- Does not track renames and deleted files. (yet)
- Does not deduplicates content (within- or cross-sessions).

*Warning: This is an opinionated tool for a very special use-case.*
*If you are unsure about it, please use a different backup tool.*

The goal of this tool is to create incremental cold storage archives that can
be stored on offline hard drives at untrusted offsite locations (or cloud storage).
The tool keeps track of the already processed files in a local repository, and
the archived files can be shipped out and kept offline (until a restore is needed).

**NOTE: The tool is experimental and may have breaking changes in the future.**

## Example use

```
dart pub global activate chill 0.1.0

dart pub global run chill init \
  --repository ~/path/to/local/repository \
  --source /path/to/input/one \
  --source /path/to/input/two

# backup session with a 800 GiB limit
dart pub global run chill backup \
  --repository ~/path/to/local/repository \
  --output /mnt/disk1/targetdir \
  --limit 800gib
```

```
# restoring
dart pub global run chill restore \
  --repository ~/path/to/local/repository \
  --input /mnt/disk1/targetdir \
  --output /path/to/restore
```

## Respository

`chill` stores its main `chill.yaml` config and its tracking data locally.
This is considered a trusted location and the repository itself is not
encrypted.

Each `backup` command creates a new session file in the `sessions/` subdirectory.
The file contains the session's encryption key and the file chunks that are
stored in the output blob. (Useful information for both incremental updates and
restore)

**It is strongly advised to create separate backups of the repository after each session.**

## Cryptography

The tool uses `ChaCha20-Poly1305-AEAD` block cypher to encrypt each content
chunk that is written in a backup session. The encryption key is stored in
the repository's session file, the `nonce` and the `mac` is stored alongside
the ciphertext. Each chunk is prepended by a random number of random bytes.
