# Release Baseline Wizard

Use `bin/collect-release-baseline.sh` when a new image is approved for
Integration or Production. It records the deployment commit, image tag and
digest, source archive checksum, and database dump checksum in a Markdown file.

The wizard does not contact AWS and does not require ECR `DescribeImages`
permission. If the image is already present locally, it obtains the registry
digest from Docker. Otherwise, it asks for the digest shown by the image pull
or the GitHub Actions/ECR record.

## Run it

From the project root:

```bash
bash bin/collect-release-baseline.sh
```

The default output is a timestamped file under `docs/`. A different output path
may be supplied:

```bash
bash bin/collect-release-baseline.sh docs/RELEASE_BASELINE-2026-10-08.md
```

The wizard calculates the source and database checksums from the files on the
current computer. This avoids copying long checksum values between computers.

## What the values mean

- Deployment commit SHA: the GitHub Actions run’s full deployment-project SHA.
- Image tag: normally the same full deployment-project SHA.
- Image digest: the immutable `sha256:...` registry digest.
- Source archive checksum: verifies the Laminas source payload.
- Database dump checksum: verifies the development/test data payload.

None of these values are credentials. Do not enter passwords or paste `.env`
contents into the generated document.

## After running it

1. Review the generated Markdown file.
2. Add the actual browser and integration test results.
3. Confirm the file contains no secrets.
4. Commit it as the record for that approved release.

Create a new baseline file for each approved release; do not overwrite an older
release record.

