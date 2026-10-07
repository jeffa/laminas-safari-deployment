# Waiver Patch — DEV Application Runbook

This runbook applies the confirmed waiver corrections to the existing DEV application source.

Apply this waiver patch first. Do not apply the SMTP/email patch at the same time.

## What this patch corrects

The patch addresses confirmed defects in KNO/drop-off, Adult Fitness, Kid’s Fitness, and Season Camp workflows. It corrects waiver initialization, waiver type selection, PDF path/date handling, form-field name mismatches, and Adult Fitness existing-waiver conversion.

The patch changes application source files only. It does not modify the database schema or production data.

## Before starting

Work from the DEV application source directory—the directory containing `module/`, `config/`, and `public/`.

Confirm the working tree is clean:

```bash
git status --short
```

If the command prints existing changes, stop and resolve them before continuing. Do not apply the patch over unrelated uncommitted work.

Create a safety branch and checkpoint commit:

```bash
git switch -c apply-waiver-patch
git add -A
git commit -m "Checkpoint before waiver patch"
```

If DEV is not managed by Git, make a dated copy of the application directory instead.

## Obtain the patch

Copy `patches/waiver-dropoff.patch` from this project to the DEV source directory. For example:

```bash
scp patches/waiver-dropoff.patch \
  ${DEV_USER}@${DEV_HOST}:/path/to/dev/application/
```

Use the actual DEV SSH variables and application path.

## Perform a dry run

From the DEV application source directory:

```bash
patch --dry-run -p1 < waiver-dropoff.patch
```

The dry run must complete without `FAILED`, `malformed patch`, or rejected hunks. If it fails, stop and save the complete output. Do not force the patch.

## Apply the patch

After a successful dry run:

```bash
patch -p1 < waiver-dropoff.patch
git diff --check
git diff --stat
git diff
```

The expected files are:

```text
module/Application/src/Model/Resources/WaiverDropoff.php
module/Application/src/Model/Resources/WaiverAdultClass.php
module/Application/src/Model/Resources/WaiverCamp.php
module/Application/src/Controller/CartController.php
```

Commit the reviewed source changes:

```bash
git add \
  module/Application/src/Model/Resources/WaiverDropoff.php \
  module/Application/src/Model/Resources/WaiverAdultClass.php \
  module/Application/src/Model/Resources/WaiverCamp.php \
  module/Application/src/Controller/CartController.php
git commit -m "Fix waiver creation and existing-waiver workflows"
```

## Deploy and verify DEV

Use the normal DEV deployment procedure. Clear the application/config cache if DEV uses one.

Test these workflows one at a time:

1. Create a new KNO/drop-off waiver.
2. Create a new Adult Fitness waiver.
3. Apply an existing Adult Fitness waiver.
4. Create a new Kid’s Fitness waiver.
5. Apply an existing Kid’s Fitness waiver.
6. Create a new Season Camp waiver.

For each test, confirm the page completes normally, the waiver is saved, the PDF is generated, and the expected email is sent when applicable.

Do not apply the SMTP patch until this waiver patch has been reviewed and tested independently.

## Rollback

If the patch causes a problem, stop testing. Review the checkpoint before changing shared DEV:

```bash
git log --oneline -3
git diff HEAD~1..HEAD --stat
```

If the patch is the latest commit and no later work exists, the backend coder may use:

```bash
git revert HEAD
```

Do not use a destructive reset on shared DEV without the backend coder’s agreement.

## After successful DEV review

Once the backend coder approves the source changes and testing passes:

1. Obtain a fresh application source archive containing the reviewed changes.
2. Replace the local ignored `input/laminas-app.tar.gz` payload.
3. Confirm the deployment-only waiver patch is no longer needed.
4. Remove the waiver patch application from the deployment image.
5. Perform a clean EC2 build and final smoke test.

Only then should the temporary deployment patch be removed from this project.

