# ECR Repository Description

Use the following description when creating the private ECR repository:

> Private Amazon ECR repository for immutable Docker images of the Laminas Safari application stack. Images are built from the `jeffa/laminas-safari-deployment` project for `linux/amd64` and `linux/arm64`, and are tagged with the source Git commit SHA for traceable deployments and rollback. Images contain the application runtime only; database data, environment files, SMTP credentials, CAPTCHA secrets, and other runtime secrets are not included. Application licensing follows the licensing terms of the Laminas application source; this repository grants no additional license.
