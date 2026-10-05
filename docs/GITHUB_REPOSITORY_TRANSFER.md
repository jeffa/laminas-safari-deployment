# GitHub Repository Transfer Checklist

This checklist moves `laminas-safari-deployment` from the personal GitHub
namespace to the business GitHub account or organization.

The transfer should happen before the next GitHub Actions or secret-management
changes so the project’s ownership and automation identity are correct from the
start.

## Before transferring

1. Confirm the target business GitHub username or organization name:

   ```text
   BUSINESS_GITHUB_OWNER
   ```

2. Confirm that the target owner is ready to accept the repository.
3. Commit and push all intended local documentation and configuration changes.
4. Confirm the working tree is clean:

   ```sh
   git status --short
   ```

5. Confirm the repository does not contain:

   - `.env`
   - Application source under `app/`
   - Payloads under `input/`
   - Database dumps
   - Passwords, API keys, or private keys

The repository currently contains deployment configuration and documentation;
the application source archive and database dump remain intentionally ignored.

## Transfer the repository

On GitHub:

1. Open `jeffa/laminas-safari-deployment`.
2. Open **Settings**.
3. Scroll to **Danger Zone**.
4. Choose **Transfer**.
5. Select the business organization or enter the business GitHub username.
6. Keep the repository name `laminas-safari-deployment` unless the business
   standard requires a different name.
7. Type the repository name to confirm the transfer.
8. Complete any confirmation or acceptance step required by GitHub.

GitHub repository transfers preserve the repository contents and history, but
the repository owner changes. Review Actions, collaborators, branch protection,
environments, and repository variables after the transfer.

Reference: <https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository>

## Update the local Git remote

After the transfer is complete, update the local checkout. Replace
`BUSINESS_GITHUB_OWNER` with the actual business account or organization name:

```sh
git remote set-url origin \
  git@github.com:BUSINESS_GITHUB_OWNER/laminas-safari-deployment.git
git remote -v
git fetch origin
git branch --set-upstream-to=origin/main main
git status --short --branch
```

The branch should report that it tracks the new `origin/main`.

## Update the AWS GitHub Actions trust policy

The current AWS role trusts the personal repository subject:

```text
repo:jeffa/laminas-safari-deployment:ref:refs/heads/main
```

After the transfer, update the trust policy for
`GitHubActionsLaminasEcrPublisher` so the repository subject uses the business
owner:

```text
repo:BUSINESS_GITHUB_OWNER/laminas-safari-deployment:ref:refs/heads/main
```

If the business account uses GitHub’s newer organization/repository ID subject
format, retain the corresponding `StringLike` pattern from:

```text
docs/aws/github-actions-ecr-trust-policy.json
```

The AWS account, ECR repository, role ARN, and ECR image URI do not change.
Only the GitHub repository identity in the role trust relationship changes.

## Verify GitHub Actions

1. Open the transferred repository’s **Actions** tab.
2. Confirm the workflow is present:

   ```text
   Build and publish Laminas application image
   ```

3. Confirm the workflow still has permission to request an OIDC token.
4. Run the workflow with the approved source archive URL and checksum.
5. Confirm the image is published to the existing private ECR repository.

Do not create a new ECR repository or a new publisher role unless the business
AWS account is also changing.

## Verify the final state

Confirm all of the following:

- GitHub repository URL uses the business owner.
- Local `origin` uses the business repository.
- The repository remains free of `.env` and ignored payloads.
- The AWS trust policy names the business repository.
- GitHub Actions can publish to the existing ECR repository.
- The private ECR image can still be pulled by authorized systems.
- The public ECR repository created during the experiment contains no image.

After these checks, continue with the developer Docker Desktop test and the
managed-secret work for Step #5.
