# Release Baseline

This document identifies the known-good application image and payloads used to
begin milestone 5. The values are checksums and image identifiers, not secrets.

## Baseline identity

```text
Recorded: 2026-10-07
Environment: Development / Docker Desktop validation
Deployment project commit: a662a9776ef3f8660c6205394bf7ce2163d7d1d1
```

## Application image

```text
ECR repository:
767397722370.dkr.ecr.us-east-1.amazonaws.com/laminas-safari

Image tag:
a662a9776ef3f8660c6205394bf7ce2163d7d1d1

Image digest:
sha256:d12e728977962a1b24fc418cb4a21492d3dedf6461e52dcfa7ae7c8c59e2dbe6
```

The image was pulled successfully on Docker Desktop using the commit-SHA tag.

## Source payload

```text
File: input/laminas-app.tar.gz
SHA-256: 8793f5eded72154342318a3563a25258f1d8684c3ed979af71e1df5626b537f6
```

## Database payload

```text
File: input/horsesns_safari-dev.sql.gz
SHA-256: 185854ca184ae62c1ef389369c6f588c979b510a381b44d411c24d1ac01a1e7d
```

The database dump is development data and must remain outside Git. Review and
sanitize it before distributing it to additional developers or environments.

## Validation completed

- GitHub Actions built and published the multi-architecture image.
- Docker Desktop pulled the image successfully.
- The application loaded successfully.
- Password-reset email was sent and received.
- Password reset and login were verified.
- Waiver workflows were previously verified in the containerized environment.

## Known limitation

There were no active events available for a final repeat of every waiver
workflow during this baseline check. The previously tested waiver corrections
remain part of the application source and image.

## Use of this baseline

Use the image tag or digest when reproducing this exact application version.
Use the payload checksums when verifying that the source archive and database
dump are the intended inputs.

For a future release, create a new baseline record rather than overwriting this
one. Record the new deployment commit, image tag and digest, source checksum,
database checksum, and test results.

