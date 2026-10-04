# AWS Free Tier storage note

As of October 2026, AWS documents up to 30 GB of Amazon EBS storage as Free
Tier eligible, including General Purpose SSD volumes such as `gp2` and `gp3`.
This allowance is subject to the account's Free Tier plan, account age, region,
and aggregate monthly usage.

For this project, the default EC2 root volume was too small for Docker images,
BuildKit cache, the extracted Laminas application, and the MariaDB volume. A
30 GiB `gp3` root volume should provide useful headroom while remaining within
the documented storage allowance when the account is otherwise eligible.

Before provisioning, check the account's current Free Tier usage and billing
dashboard. After tearing down a test instance, release its EBS volume and any
unused snapshots so storage charges do not continue.

References:

- [AWS EBS pricing and Free Tier](https://aws.amazon.com/ebs/pricing/)
- [AWS EC2 Free Tier usage](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html)

