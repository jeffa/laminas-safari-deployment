# Laminas Environment and Production Roadmap

This document records the recommended path from the proven single-instance Laminas development deployment to repeatable development, integration, staging, and production environments.

The current EC2/Docker Compose deployment is a successful baseline. The next stages should preserve that working path while gradually separating application artifacts, infrastructure, secrets, persistent data, and traffic management.

## Current milestone

The following workflow has been tested successfully from a clean start:

1. Terraform provisions the EC2 instance.
2. Ansible provisions Docker and Docker Compose support.
3. Local deployment scripts package and transfer the Laminas stack.
4. The remote deployment wrapper builds and starts the application and database containers.
5. The database dump is restored.
6. The application passes its health checks and serves the site.

This should be preserved as the known-good development baseline before introducing production infrastructure.

## Experimental SMTP branch follow-up

The deployment patch now sends password-reset mail successfully through cPanel SMTP. Before merging this branch:

- [ ] Apply the confirmed PHPMailer connection fix to the Laminas application source in DEV.
- [ ] Validate password-reset delivery in DEV using the source change.
- [ ] Remove the corresponding deployment patch hunk after the source change is released.
- [ ] Include the validated email change in the next production deployment cycle.

## Phase 1: Freeze the working baseline

Commit the successful deployment changes and create a Git tag, for example:

```text
laminas-dev-v1.0.0
```

The tag provides a recovery point if future infrastructure or application changes introduce problems.

Keep both deployment approaches available during the transition:

- The segmented scripts remain the easiest troubleshooting path.
- The wrapper remains the preferred repeatable deployment path once validated.

## Phase 2: Separate the deployment artifacts

Treat the following as separate deliverables:

| Artifact | Responsibility |
| --- | --- |
| Terraform | AWS infrastructure and networking |
| Ansible | Host-level Docker/runtime setup |
| Docker image | Laminas application runtime |
| Compose | Local or single-instance development orchestration |
| Environment/secrets | Environment-specific configuration |
| Database dump or migrations | Database initialization and test data |

This separation makes it possible to reuse the same application image in several environments without rebuilding the entire server.

## Phase 3: Publish the application image to ECR

The current Dockerfile should become the source for an immutable application image. Build the image in CI or on a controlled build host, then push it to a private Amazon ECR repository. ECR supports Docker and OCI image publishing:

- [Pushing a Docker image to Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)

Use immutable, traceable tags based on the Git commit:

```text
laminas-app:git-a1b2c3d
laminas-app:dev
laminas-app:production
```

Production deployments should use the commit-specific tag rather than relying on a floating `latest` tag.

The EC2 deployment should eventually pull the selected image from ECR instead of building the image directly on the instance.

## Phase 4: Move secrets into managed storage

The ignored, prepopulated `.env` file is practical for the current disposable development workflow. It should not become the production secret-management model.

The following values should eventually be stored in AWS Secrets Manager or SSM Parameter Store:

- Database passwords
- Database root or administrative credentials
- SMTP credentials
- CAPTCHA keys
- Application-specific secrets
- Any third-party API credentials

The deployment role should receive permission to read only the secrets required by that environment. Secrets should not be baked into Docker images, AMIs, source tarballs, or Terraform state where avoidable.

## Phase 5: Move MariaDB out of the application host

The MariaDB container is appropriate for the current development stack. Multiple application instances should not depend on a database container running on one application EC2 host.

The production direction should be Amazon RDS for MariaDB. RDS Multi-AZ deployments maintain a standby instance in another Availability Zone for failover support:

- [Amazon RDS Multi-AZ deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)

The migration will need to cover:

1. Creating the RDS instance and database user.
2. Restricting database access to the application security group.
3. Importing the approved database dump.
4. Updating the application configuration to use the RDS endpoint.
5. Testing sessions, password resets, email workflows, and other database-backed features.
6. Configuring backups, retention, maintenance, and monitoring.

Moving to RDS also removes the current operational issue where MariaDB credentials are tied to the lifecycle of a persistent Docker volume.

## Phase 6: Externalize writable application data

Multiple application instances must be able to access the same user-created data. Any data written only to an individual container or EC2 instance can disappear or become unavailable when traffic moves to another instance.

Review and classify all writable paths, including:

- Uploaded files and documents
- Generated PDFs or waivers
- User sessions
- Temporary files
- Application logs
- Cache data

Likely target services are:

| Data | Possible target |
| --- | --- |
| Uploaded documents and assets | Amazon S3 or EFS |
| Sessions | Shared MariaDB or Redis |
| Application logs | CloudWatch Logs |
| Backups | RDS automated backups and S3 |

This review is required before scaling beyond one application instance.

## Phase 7: Add an Application Load Balancer

The eventual production request path should be:

```text
Internet
    |
    v
HTTPS Application Load Balancer
    |
    +-- Healthy Laminas application instance
    +-- Healthy Laminas application instance
    |
    v
Amazon RDS for MariaDB
```

An Application Load Balancer can distribute requests across targets and route traffic only to healthy targets:

- [AWS Elastic Load Balancing documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [Application Load Balancer target groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)

The recommended HTTPS arrangement is:

1. Request or import a certificate through AWS Certificate Manager.
2. Create an HTTPS listener on the ALB.
3. Redirect HTTP traffic to HTTPS.
4. Configure the target group health check.
5. Allow inbound web traffic to the application instances only from the ALB security group.

An HTTPS listener can terminate TLS at the load balancer, allowing the application containers to focus on serving the application:

- [Application Load Balancer listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html)

The application health endpoint should be lightweight and should return failure when the application is not able to serve requests correctly.

## Phase 8: Add autoscaling

Once the application is stateless and persistent data is externalized, use an EC2 Auto Scaling Group with a Launch Template.

The Launch Template should specify:

- The approved AMI or host image
- The instance type
- The application IAM role
- The security group
- User data or a bootstrap process
- The Docker image version to deploy

The Auto Scaling Group should register instances with the ALB target group and replace unhealthy instances automatically.

The least disruptive progression is:

1. One EC2 instance and Compose.
2. Multiple EC2 instances behind an ALB.
3. Auto Scaling Group with a Launch Template.
4. Optional migration to ECS/Fargate if container orchestration becomes worthwhile.

The application image should remain independent of whether it is ultimately run by Compose, EC2, or ECS.

## Phase 9: Introduce environment separation

Create explicitly separated Terraform environments or stacks:

```text
dev
integration
staging
production
```

Each environment should have its own:

- AWS resources
- Database and credentials
- Secrets
- Domain or subdomain
- Backups and retention policy
- Deployment approval rules

Development database data must not be promoted to production. Production data must never be copied into development without an approved sanitization process.

## Phase 10: Add CI/CD and rollback

The eventual pipeline should perform the following actions:

1. Run application tests and static checks.
2. Scan source and build output for secrets.
3. Build the Docker image.
4. Tag it with the Git commit SHA.
5. Push it to ECR.
6. Deploy the selected image tag to the target environment.
7. Run application and database connectivity checks.
8. Verify the ALB health checks.
9. Record the deployment version.
10. Support rollback to the previous known-good image.

Database schema changes should be handled separately from application image deployment. A failed application deployment should not leave the database in an irreversible state.

## Recommended immediate next steps

The next practical milestones are:

1. Commit and tag the current successful deployment.
2. Document the exact known-good Terraform, Ansible, Compose, and wrapper versions.
3. Create a private ECR repository.
4. Modify the deployment to pull a tagged image from ECR.
5. Add a small deployment smoke test for the home page, assets, database connection, and health endpoint.
6. Inventory all writable application paths.
7. Design the RDS migration.
8. Add ALB and HTTPS after the application can run correctly without local MariaDB state or local uploaded files.

The most important architectural rule is: **do not attempt multiple production application copies until the database, sessions, uploads, and other writable state are shared or externalized.**
