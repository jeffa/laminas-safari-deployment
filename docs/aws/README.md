# AWS IAM Policy Documents

These policy documents support publishing the Laminas Safari image from GitHub
Actions to the private ECR repository in `us-east-1`.

## Files

- `github-actions-ecr-trust-policy.json` is the IAM role trust policy. Attach it
  when creating `GitHubActionsLaminasEcrPublisher`.
- `ecr-publisher-permissions-policy.json` is the inline permissions policy for
  that role. It permits authentication and image pushes only to the
  `laminas-safari` repository.
- `ecr-puller-permissions-policy.json` is the inline permissions policy for an
  EC2 instance role. It permits authentication and image pulls only from the
  `laminas-safari` repository.

The trust policy is limited to the `main` branch of the configured
`laminas-safari-deployment` repository through GitHub Actions OIDC. After a
repository transfer, update the owner in the trust-policy JSON and in AWS.
The policy files contain account and repository identifiers, not credentials or
secrets.

If the AWS account, repository, GitHub owner, repository name, or allowed branch
changes, update these documents before recreating the role.
