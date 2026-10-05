# A Safer Development and Testing Environment for Safari Run

## Executive summary

Safari Run currently has one Development server that hosts both the website and
its database. That arrangement works for day-to-day maintenance, but it creates
business risk when major changes are being developed:

- Developers can accidentally interfere with one another.
- A broken change can affect everyone using the Development server.
- There is no separate environment that closely resembles Production.
- Important changes cannot be tested safely before they are released.
- Development database data and application files are concentrated on one host.

The proposed solution is a small, controlled development platform with three
clear purposes:

1. **Integration environment:** a shared server used to test complete changes
   before Production.
2. **Individual developer sandboxes:** isolated environments where developers
   can work without blocking one another.
3. **Repeatable application builds:** the same tested application package can
   be moved from development to integration and eventually to Production.

This does not require replacing the current Production system immediately. It
creates a safer path toward Production while preserving the existing workflow
until the new process is proven.

## The current situation

The company currently works primarily from one Development server. That server
contains both:

- The web application.
- The database used by the application.

Access has historically been managed through cPanel. SSH access and command-line
deployment are now being introduced because they provide better control over
containers, backups, logs, and repeatable deployment steps.

The current shared-server model creates a common failure point. If one developer
uploads a broken change, changes a database table, or leaves an unfinished
experiment in place, other people may be unable to work or may unknowingly test
against an unstable system.

## The proposed model

### 1. Integration server

The Integration server is a shared testing environment that is separate from
both individual developer work and Production.

It is used for:

- Testing a complete feature before release.
- Testing database changes.
- Testing email and external services.
- Confirming that the application works as a complete system.
- Demonstrating a release candidate to the owner or stakeholders.

Integration should use a controlled copy of Development data or sanitized test
data. It should never be treated as the only copy of important information.

### 2. Individual developer sandboxes

Each developer can run an isolated copy of the application on their own
computer. The application runs in Docker Desktop, which provides a consistent
environment without requiring every developer to install and configure the same
PHP, Apache, database, and supporting software by hand.

A developer can:

- Work on a feature without changing another developer’s environment.
- Break their own copy without taking down the shared Development server.
- Restore a clean database when an experiment goes wrong.
- Test the same type of application image that Integration uses.

The sandbox is disposable by design. If it becomes confused or damaged, it can
be stopped, removed, and recreated from the approved application image and test
database dump.

### 3. Repeatable application images

Instead of copying unfinished application files directly onto a server, the
application is packaged into a versioned Docker image.

An image is like a prepared application box. It contains the application runtime
and code, but not environment-specific passwords or database contents.

Each image is identified by the source-code revision used to create it. This
means the team can answer:

- What version is running?
- Which version was tested?
- Which version should be rolled back if a problem is discovered?

The image is stored in a private Amazon ECR repository. GitHub Actions builds
the image and publishes it for both Intel/AMD servers and Apple Silicon Macs.

## How a change would move through the process

The normal flow would be:

```text
Developer sandbox
        |
        v
Code review and automated image build
        |
        v
Integration server
        |
        v
Owner/stakeholder acceptance
        |
        v
Production deployment
```

The important change is that Production is no longer the first place where a
major change is tested. Integration becomes the proving ground.

## What this prevents

This model reduces the chance that:

- One developer blocks the rest of the team.
- An unfinished feature is mistaken for an approved feature.
- A database experiment damages the shared Development database.
- A deployment cannot be reproduced because nobody remembers the exact steps.
- A release cannot be rolled back because the previous version was not preserved.
- A server must be repaired manually after a failed file upload.

It also gives the company a clearer separation between development, testing, and
Production responsibilities.

## What this does not promise

This platform does not eliminate the need for:

- Backups.
- Code review.
- Database migration planning.
- Access control.
- Monitoring.
- A deliberate Production release process.

It makes those activities easier to perform consistently. It does not make an
unsafe change safe merely because it runs in Docker.

## Security and data protection

Passwords, SMTP credentials, CAPTCHA keys, and other secrets are kept outside
the application image and source repository.

Development and Integration should use separate credentials from Production.
Database data should be reviewed before being copied into a developer sandbox.
Where practical, personally identifiable or sensitive customer data should be
removed or anonymized before it is used outside Production.

Access to the private application image is granted only to approved users and
systems. Developers do not need permission to publish images or modify AWS
infrastructure merely to run a sandbox.

## Cost and operational impact

The platform introduces some additional AWS storage, compute, and administration
costs. The cost can be controlled by:

- Keeping Integration small when it is not being tested.
- Stopping disposable servers when they are not needed.
- Using smaller development resources than Production resources.
- Retaining only the image versions and database backups required by policy.
- Reviewing AWS usage regularly.

The cost should be compared with the cost of a failed Production deployment,
lost development time, emergency repairs, or a customer-facing outage.

## Work completed so far

The initial platform has already demonstrated that:

- The Laminas application can be packaged as a Docker image.
- The image can support both Intel/AMD and Apple Silicon systems.
- The application can run with a separate MariaDB container.
- SMTP email works from the containerized application.
- The image can be published to a private Amazon ECR repository.
- EC2 can authenticate and pull the private image.
- The pulled image passed a full browser smoke test, including password reset
  email, password reset, and login with the new password.

These results prove the core technical path before it is introduced into the
normal team workflow.

## Suggested implementation phases

### Phase 1: Establish the development baseline

- Keep the current Development server available.
- Document the known-good application and database versions.
- Confirm that secrets are not stored in source control or Docker images.

### Phase 2: Make developer sandboxes easy to create

- Provide a short onboarding guide for Docker Desktop.
- Provide approved test data and local configuration instructions.
- Give developers read-only access to the private application image.
- Provide a simple command or script for starting the local stack.

### Phase 3: Establish Integration

- Provision a separate Integration server.
- Pull a specific, approved image from the private registry.
- Restore controlled Integration database data.
- Test application workflows, email, uploads, and database changes.

### Phase 4: Improve release safety

- Require a successful Integration test before Production deployment.
- Preserve the previous Production image for rollback.
- Move shared secrets into managed storage.
- Add monitoring, backups, and a written rollback procedure.

## Decisions requested from the owner

The owner does not need to decide technical implementation details such as
Docker commands or IAM policy documents. The important business decisions are:

1. Approve a separate Integration environment.
2. Approve isolated developer sandboxes as the standard development workflow.
3. Approve a modest AWS budget for Integration and related storage.
4. Approve the use of controlled or sanitized data outside Production.
5. Decide who may approve a release from Integration to Production.

## Recommended outcome

Approve the Integration server and developer sandbox initiative as a staged
improvement. Keep the existing Development and Production systems operating
until the new workflow has been used successfully for real changes.

The goal is not to add technology for its own sake. The goal is to give the
company a safer place to develop, a reliable place to test, and a repeatable way
to release changes without making one shared server carry every responsibility.
