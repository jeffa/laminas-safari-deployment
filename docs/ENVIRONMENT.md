# Laminas environment questionnaire

Use this checklist to gather the information needed to build the first Laminas test server and design a reusable development/integration environment.

Do not include passwords, API keys, private keys, or other secrets in this document. Record secret names and where they will be supplied instead.

## 1. First environment

What should we build first?

```text
Environment type: _DEV__________________________________________
Primary purpose: __POC___________________________________________
Expected lifetime: __VERY SHORT__________________________________
Who needs access: ___JUST ME_____________________________________
Target AWS region: __US N VIRGINIA_______________________________
```

- [x] Individual developer environment
- [ ] Shared development server
- [ ] Integration/test server
- [ ] Other: _________________________________________________

Should the first server be disposable, persistent, or recreated regularly?

```text
Answer: __recreated regularly____________________________________
```

## 2. Application source

Where will the application source come from?

```text
Source archive/repository: __source tar ball_____________________
Branch or release: ___none_______________________________________
Build instructions or deployment notes: __TBA____________________
```

- [x] The source includes `composer.json`
- [x] The source includes `composer.lock`
- [x] The source includes the Laminas `public/` directory
- [x] The source includes application configuration
- [x] The source includes uploaded/static files required at runtime

If any item is missing, explain how it is currently supplied:

```text
Answer: _________________________________________________________
```

## 3. PHP and Composer

```text
Production PHP version: ___8.1____________________________________
Approved test PHP version: __same_________________________________
Composer version, if fixed: __unknown_____________________________
Required PHP extensions: ___unknown_______________________________
Required OS packages/libraries: __unknown_________________________
```

List any commands that must run after Composer installation:

```text
Commands: _______________________________________________________
```

Which dependencies are needed at runtime?

- [ ] Production dependencies only
- [ ] Development dependencies too
- [ ] PHPUnit or test tooling
- [ ] Psalm/static analysis
- [ ] Code-style tooling
- [ ] Other: _________________________________________________

## 4. Application startup and web serving

```text
Application document root: _____unknown__________________________
Required startup command: _______________________________________
Required working directory: ____unknown__________________________
Required web-server rewrite rules: _______unknown_________________
Required application environment name: __probably none____________
```

- [x] Apache is acceptable
- [ ] nginx is required
- [ ] PHP-FPM is required
- [ ] PHP’s built-in server is acceptable for development only
- [ ] Other: _________________________________________________

Does the application require a special Laminas cache/configuration command?

```text
Command: _______________________________________________________
When it must run: _______________________________________________
```

## 5. Database

```text
Database engine: ___MariahDB_____________________________________
Production version: __10.6.28_____________________________________
Test version: __________________________________________________
Database name: _____horsesns_safari_____________________________
Database username: _horsesns_safari_______________________________
Original OS/filesystem username: _horsesns________________________
Character set/collation: ________________________________________
SQL mode requirements: __________________________________________
Database configuration file(s): _________________________________
```

How is the database initialized?

- [ ] Fresh schema migrations
- [x] SQL dump restore
- [ ] Fixtures/seed data
- [ ] Combination of the above
- [ ] Other: _________________________________________________

```text
Initialization commands/order: dump includes CREATE DATABASE/USE
No additional import steps are currently known. Import with the
temporary database root account so CREATE DATABASE can succeed.
```

Database dump details:

```text
Format: __SQL compressed with gzip (.sql.gz)_______________________
Approximate size: __27 MB________________________________________
Compressed: __yes________________________________________________
Contains real client/customer data: __development data only_______
Anonymization required: __not yet determined______________________
Known import issues: __none known________________________________
```

Never place database passwords in this questionnaire or in the source archive. Describe where the application expects the values and how they can be overridden:

```text
Configuration mechanism: ________________________________________
Variable/file names: ____________________________________________
```

## 6. External services and scheduled work

List every service the application calls or expects:

| Service | Required? | Test endpoint/account | Credentials supplied by | Notes |
|---|---|---|---|---|
| Email/SMTP | | | | |
| External API | | | | |
| Object/file storage | | | | |
| Payment/service provider | | | | |
| Queue/cache | | | | |
| Other | | | | |

Does the application require background work?

```text
Workers: ________________________________________________________
Cron/scheduled tasks: ____________________________________________
Queue technology: ________________________________________________
How often: ______________________________________________________
```

## 7. Runtime data and filesystem

Which directories must be writable by the web process?

```text
Directories: ___________________________________________________
Purpose: _______________________________________________________
```

Which data must survive container recreation?

- [ ] Database
- [ ] User uploads
- [ ] Generated reports/files
- [ ] Application cache
- [ ] Logs
- [x] None; everything can be recreated
- [ ] Other: _________________________________________________

## 8. Networking and access

```text
Expected URL/hostname: __________________________________________
HTTP required: _____yes__________________________________________
HTTPS required: ____no___________________________________________
Allowed browser/source IPs: ______________________________________
SSH allowed from: ___already configured - my computer only_______
```

- [x] Public HTTP is acceptable for the temporary lab
- [ ] Access must be private/VPN-only
- [ ] A DNS name is available
- [ ] TLS certificate is available
- [x] No public database access

## 9. Security and data handling

```text
Data classification: ____________________________________________
Can production data be copied to AWS? no, but this is from dev however
Required anonymization rules: ___________________________________
Required retention period: ______________________________________
Who may access the server: ____public facing web server__________
```

- [x] No secrets in Git
- [x] No production credentials in the lab
- [ ] Separate test credentials are available
- [x] Database dump is safe for development
- [?] Database dump needs sanitizing
- [?] Logs may contain sensitive data
- [ ] Logs need redaction or restricted access

## 10. Reusable image and environment strategy

Which workflow do you want for each environment?

| Environment | Source workflow | Database workflow | Expected lifetime |
|---|---|---|---|
| Developer | | | |
| Shared development | | | |
| Integration | | | |
| Demo | | | |

Choose the preferred application delivery method:

- [ ] Developers edit a mounted source directory
- [ ] Servers pull a prebuilt Docker image
- [ ] CI builds and publishes Docker images
- [x] Terraform/Ansible copies a source tarball
- [ ] Undecided

```text
Preferred image registry: ____________N/A_________________________
Image naming/tagging convention: _______N/A_______________________
CI system: _______________________________N/A____________________
Who can publish images: ____________________N/A__________________
```

How should new environments be created?

- [ ] One documented manual command
- [ ] Terraform command plus Compose
- [ ] An automated CI workflow
- [x] A reusable Terraform module
- [ ] A reusable AMI as well as a Docker image
- [ ] Other: _________________________________________________

## 11. Acceptance checks

What must be true before the environment is considered working?

- [x] Application homepage loads
- [x] User login works
- [x] Database reads work
- [x] Database writes work
- [ ] File uploads work
- [ ] Email is captured or delivered safely
- [ ] Background jobs run
- [ ] Automated tests pass
- [ ] Health-check endpoint responds
- [x] Logs are accessible
- [x] Environment can be destroyed and recreated
- [ ] Other: _________________________________________________

Additional acceptance requirements:

```text
__________________________________________________________________
__________________________________________________________________
```

## 12. Open questions and notes

```text
__________________________________________________________________
__________________________________________________________________
__________________________________________________________________
```
