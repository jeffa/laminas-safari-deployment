# Franchise Integration Program Discovery Checklist

This checklist is for gathering information about the Visual Basic integration
programs that run on dedicated computers at franchise locations.

The purpose is to understand and preserve their current operation while the
Laminas application is moved to a new deployment environment. It is not a code
review or an assignment of responsibility. The questions are designed to
uncover dependencies before the current host is changed or retired.

## How to introduce the conversation

> We are planning to move the web application to a more repeatable platform.
> We are not replacing the franchise integration programs immediately. We
> want to document how they communicate with the application so we can keep
> them working during the transition and test the new environment safely.

Please answer what is known, mark unknown items as unknown, and identify who
can verify each answer. Do not place passwords, API keys, private certificates,
or other secrets in this document.

## 1. Identify each program

For every integration program, record:

- Program name and business purpose;
- Franchise/location where it runs;
- Computer name and Windows version;
- 32-bit or 64-bit application;
- Executable filename and installed version;
- Who owns and supports it;
- Whether it runs manually, at Windows startup, or on a schedule;
- Whether more than one copy can run at the same time;
- What business process stops if it is unavailable;
- Whether a replacement or newer version exists.

## 2. Understand how it communicates

Ask:

- Does it call the Laminas application over HTTP or HTTPS?
- What hostname or URL does it use?
- Does it use SOAP, REST, a database connection, shared files, email, or more
  than one of these?
- What WSDL, endpoint, or documentation does it use?
- Does it call `/soap/soap`, `/soap/wsdl`, or another route?
- Is the endpoint hard-coded in the executable or stored in an `.ini`, XML,
  JSON, registry, or other configuration file?
- Does it use a DNS name or a fixed IP address?
- Does it require a particular port, proxy, VPN, or firewall rule?
- Does the server need to initiate a connection back to the franchise
  computer?

The current Laminas source contains SOAP support and routes named
`/soap/soap`, `/soap/wsdl`, and `/soap/writewsdl`. Confirm which, if any, are
used by the franchise programs rather than assuming that every SOAP route is
still active.

## 3. Document authentication and security

Ask:

- How does each program authenticate?
- Does it use a username/password, API token, client certificate, Windows
  credentials, IP allowlist, or no authentication?
- Are credentials unique per franchise or shared by all locations?
- Where are credentials stored on the Windows computer?
- Can credentials be rotated without rebuilding the executable?
- Does the program validate the server TLS certificate?
- What TLS versions and certificate authorities does it support?
- Are franchise IP addresses allowlisted anywhere?
- Does the program transmit personal, customer, payment, or operational data?
- What data must never appear in logs or error messages?

Do not request that credentials be emailed or pasted into project documents.
Record only the storage method and rotation procedure.

## 4. Identify data and side effects

For each operation, ask:

- What starts the operation?
- What records does it read?
- What records does it create, update, or delete?
- Which database tables or application services are involved?
- Is the operation safe to repeat if the first response is lost?
- Does it create files, PDFs, exports, or local backups?
- Does it send email or interact with a payment system?
- What identifier connects the franchise transaction to the web application?
- Are timestamps, time zones, and date formats significant?
- Does the program expect a particular response XML structure, status code, or
  message text?

Request sanitized sample requests and responses where possible. Remove names,
email addresses, tokens, payment details, and other sensitive values first.

## 5. Understand failure and recovery behavior

Ask:

- What happens when the server is unavailable?
- Does the program retry automatically?
- How many times, and at what interval?
- Does it queue work locally for later delivery?
- Can an operator retry one item without retrying everything?
- How are successes and failures displayed?
- Where are logs stored on the Windows computer?
- How long are logs retained?
- How can support distinguish a network failure from an application failure?
- What happens if the request succeeds but the response is lost?
- Is there a reconciliation or replay procedure?

This information is essential before changing DNS, moving the endpoint, or
introducing a load balancer.

## 6. Discover current-host dependencies

Ask specifically whether the programs depend on:

- The current public hostname or a legacy hostname;
- A fixed public IP address;
- A cPanel path or virtual host;
- A specific PHP or SOAP behavior;
- A direct MariaDB/MySQL connection;
- A shared network folder or FTP/SFTP location;
- Files under the current web root;
- A server-side certificate or client certificate;
- Firewall rules based on the current host;
- A scheduled job or Windows task on the current server;
- A particular response latency or timeout;
- The current server's local time zone.

Identify anything that would break if the current host were replaced but the
public DNS name remained the same.

## 7. Confirm the migration contract

Before building the new Integration environment, agree on:

- The endpoint hostname used for Integration testing;
- Whether the programs can select an endpoint by configuration;
- Whether a test copy can run beside the production copy;
- A non-production account or test franchise/location;
- Safe test records and cleanup rules;
- Required firewall and allowlist changes;
- Required DNS records and certificate names;
- A version of the WSDL or API contract to freeze for testing;
- The rollback procedure to the current host;
- The person authorized to approve a production endpoint change.

The preferred migration pattern is to keep the existing hostname and service
contract stable while changing the server behind it. If that is impossible,
the programs must support a configurable endpoint or receive a coordinated
configuration update.

## 8. Define the minimum Integration test

Create a short test that can be repeated before and after a deployment. It
should verify, as applicable:

1. The program resolves the Integration hostname.
2. TLS negotiation succeeds.
3. Authentication succeeds without exposing credentials.
4. A harmless read operation succeeds.
5. A controlled write operation creates the expected test record.
6. The response is accepted by the program.
7. A deliberate failure is logged and recoverable.
8. A retry does not create an unintended duplicate.
9. The production endpoint remains unchanged during the test.

Record the test date, program version, endpoint, result, and operator. Do not
record secrets or real customer data.

## 9. Questions to close before production migration

Do not schedule the production cutover until these questions have answers:

- Which programs are business-critical?
- Which programs communicate with the application, and by which protocol?
- Which endpoint and certificate names must remain stable?
- Are any programs dependent on a fixed IP address?
- Can every program be tested against Integration?
- Can every program be pointed back to the current host quickly?
- Are database, file, SOAP, and authentication dependencies documented?
- Are logs and retry behavior understood?
- Is there a rollback owner and a support contact at each affected franchise?
- Has a complete end-to-end test passed using the production-like image?

## Suggested evidence to collect

Ask for copies or screenshots only after sensitive values have been removed:

- Program inventory and installed versions;
- Non-secret configuration names and endpoint fields;
- WSDL or API documentation;
- Sanitized request/response samples;
- Windows Task Scheduler entries;
- Firewall and VPN requirements;
- Redacted application logs from a successful and failed call;
- A simple current-state network diagram;
- Existing support or recovery instructions.

Store the evidence in an access-controlled location. This deployment project
should contain the procedure and contract, not credentials or broad customer
data.
