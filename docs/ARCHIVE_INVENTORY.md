# Project Archive Inventory

This document records files that are historical, temporary, or intentionally
kept outside the normal build path. It prevents useful deployment history from
being mistaken for active application inputs.

## Current active workflow

These files remain part of the supported deployment workflow:

- `Dockerfile`
- `compose.yaml`
- `compose.build.yaml`
- `bin/`
- `.github/workflows/build-image.yml`
- `.env.example`
- `runtime-config/local.php`
- `docs/DEVELOPER_DOCKER_DESKTOP_SETUP.md`
- `docs/DEVELOPER_AWS_ACCESS_SETUP.md`

The Docker image now uses the corrected application source directly. It no
longer applies the waiver or SMTP patches during the build.

## Historical patches retained for reference

These files are retained until the corresponding source changes have completed
the normal Development and Production release process:

- `patches/waiver-dropoff.patch`
- `patches/waiver-field-fixes.patch`
- `patches/email-smtp.patch`

After the source changes are confirmed in Production, these may be moved into a
dated archive directory such as `archive/patches/2026-10/`. Before moving them,
update any runbooks that still describe them as active deployment steps.

The following corrective patch is superseded and should be retained only as
historical troubleshooting material:

- `patches/waiver-field-fixes-correction.patch`

It must not be applied to the clean waiver-fix branch or to the current image.

## Documentation retained as project history

These documents explain decisions, troubleshooting, and repeatable procedures;
they are not temporary logs:

- `docs/SMTP_PATCH.md`
- `docs/WAIVER_PATCH_DEV_RUNBOOK.md`
- `docs/WAIVER_PATCH_POSTMORTEM.md`
- `docs/MILESTONE_HISTORY.md`
- `docs/OWNER_PROPOSAL.md`

They should remain searchable until the replacement workflow is documented and
approved.

## Local-only files that must not be committed

The following are intentionally ignored by `.gitignore` and must remain local:

- `input/` source archives, database dumps, and local environment files
- `app/` extracted application source
- `*.tmp` diagnostic captures
- `.env` and local runtime configuration containing secrets
- `terraform.tfstate` and related Terraform state files

These files may be backed up securely outside Git when needed, but they should
not be placed in a public repository or copied into a general project archive.

## Cleanup checkpoint

At the successful completion of the SMTP and waiver source rollout:

1. Confirm the corrected source is present in Production.
2. Confirm the next image builds without applying either patch.
3. Move the historical patch files to a dated archive directory, or keep them
   in place if the backend team still uses them for legacy DEV maintenance.
4. Keep this inventory updated when files change status.

