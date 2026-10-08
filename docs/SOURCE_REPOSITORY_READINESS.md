# Milestone 5 Prerequisite: Source Repository Readiness

This checklist prepares the Laminas application source for its private GitHub
repository and for the production-ready image and release path in milestone 5.

The Developer Docker project is already functioning. This document records the
remaining work needed to make the application source reproducible, safe to
share with approved developers, and compatible with the deployment project.

## Readiness gate

Milestone 5 should not consume the new source repository until all required
items below are complete or explicitly accepted by the project owner.

The development database dump must not be distributed broadly until its
privacy review is formally approved. A technically working dump is not the
same thing as an approved dump.

## Status summary

| Area | Current finding | Status | Next action |
| --- | --- | --- | --- |
| CAPTCHA | Existing keys reject `localhost` and `127.0.0.1` | Open | Create dedicated local keys or document that CAPTCHA is tested only in QA/Integration |
| Mercury payments | `MERCURY_MODE=mock` has no effect | Decision required | Implement a real mock adapter or explicitly prohibit local payment testing |
| Payment return URLs | DEV URLs can redirect local testing to the external DEV site | Open | Separate local, QA, DEV, and production URL profiles |
| Database hostname | Source defaults to `localhost`; Compose requires `db` | Ready with contract | Preserve the runtime override and document it as mandatory |
| PHP runtime | Original source Dockerfile lacks required extensions | Ready with deployment ownership | Keep the deployment Dockerfile as the canonical runtime definition |
| Composer autoloading | Legacy PSR-4 warnings were found and cleaned up | Verify in source repo | Preserve the cleanup and require a warning review in CI |
| Writable paths | Apache needs cache and generated-document write access | Ready with runtime contract | Preserve explicit directory creation and ownership in the image |
| Database privacy | Development dump has not received formal sensitive-data approval | Blocking | Obtain approval, sanitize, or replace the dump |

## Work that can be completed now

### 1. Prepare the private source repository

When the private GitHub repository is available:

1. Import the current Laminas source from the approved working copy.
2. Preserve the PSR-4 cleanup that removed or corrected legacy files and
   filenames.
3. Add a source `.gitignore` that excludes local environment files, database
   dumps, generated documents, logs, caches, and archives.
4. Add a source `README.md` explaining that deployment is performed by the
   separate `laminas-safari-deployment` project.
5. Protect the default branch and require review for source changes.

The source repository must not receive SMTP passwords, database passwords,
CAPTCHA secret keys, payment credentials, production dumps, or private runtime
configuration.

### 2. Preserve the runtime contract

The deployment image is the proven runtime definition. The source repository
should provide application code; the deployment project should continue to
own the Dockerfile, required PHP extensions, Apache setup, Composer install,
runtime links, writable-directory ownership, and image publication.

The application must support these runtime-supplied values without requiring
developers to edit source files:

- database hostname, database name, username, and password;
- application base URL and environment mode;
- CAPTCHA public and private configuration;
- SMTP configuration;
- Mercury endpoint and payment-mode configuration;
- document and generated-file paths.

The Compose database hostname is `db`, not `localhost`. This is a deployment
contract, not a source-code default that should be silently relied upon.

### 3. Add configuration profiles

Create documented, non-secret profiles for Local Docker, QA/Integration,
shared DEV, and Production. Each profile should make the following explicit:

- database host and database source;
- public application URL;
- payment endpoints and whether payment testing is permitted;
- CAPTCHA key type and authorized domains;
- document-storage paths;
- email behavior and recipient safeguards.

Profiles should contain placeholders or references to a secret manager, not
real credentials.

### 4. Resolve the CAPTCHA policy

Choose one supported policy:

1. Dedicated local CAPTCHA keys authorize `localhost` and `127.0.0.1`.
2. Local development bypasses CAPTCHA through an explicit, safe development
   mode while QA/Integration performs real CAPTCHA testing.
3. CAPTCHA testing is prohibited locally and documented as QA/Integration-only.

The application must not present a setting that appears to enable local CAPTCHA
testing while continuing to use keys unauthorized for the local domain.

### 5. Resolve the Mercury policy

`MERCURY_MODE=mock` currently has no application effect. Before milestone 5
continues, choose one policy:

- implement and test a real mock payment adapter; or
- remove or rename the unsupported mock setting and document that payment
  testing occurs only in QA/Integration using the appropriate sandbox endpoint.

Until a real adapter exists, the second option is the safer and more truthful
policy.

### 6. Verify runtime filesystem behavior

The image build and startup checks must verify that the web process can write
only to the directories that require it, including Laminas cache and generated
documents. The source repository should not require the entire application
tree to be writable.

## Required verification after source import

Run these checks from the deployment project using the imported source:

1. Build the image with the proven deployment Dockerfile.
2. Confirm Composer optimized-autoloader generation does not introduce new
   PSR-4 warnings.
3. Start the local Compose stack with the database hostname set to `db`.
4. Confirm the application can create cache files and generated documents.
5. Confirm CAPTCHA behavior matches the selected local policy.
6. Confirm payment return URLs remain inside the selected environment.
7. Run the existing password-reset and waiver smoke tests.
8. Record the source commit, source archive checksum, image tag/digest, and
   database fixture checksum using the release baseline wizard.

## Acceptance criteria

This prerequisite is complete when:

- the source is in the private GitHub repository;
- no secrets or unapproved sensitive data are present;
- the PSR-4 cleanup is preserved;
- the deployment image builds from the imported source without unexplained
  Composer warnings;
- runtime configuration works with the Compose database service named `db`;
- writable paths work with explicit ownership;
- CAPTCHA and Mercury behavior are documented and truthful;
- local payment return URLs cannot silently redirect to shared DEV;
- the development database dump is approved, sanitized, or replaced; and
- a release baseline has been recorded.

## Ownership and boundaries

| Responsibility | Project |
| --- | --- |
| Laminas application source and business logic | Private source repository |
| Developer editing workflow | Separate Developer Docker project |
| Proven runtime image and required PHP extensions | `laminas-safari-deployment` |
| ECR publication and release traceability | `laminas-safari-deployment` |
| Environment secrets and runtime values | AWS/host secret configuration |
| Database privacy approval | Project owner and business/data steward |

This separation prevents the source repository from becoming a second,
undocumented deployment system while keeping the developer workflow simple.
