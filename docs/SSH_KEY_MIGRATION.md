# GitHub SSH Key Migration: RSA to Ed25519

## Why this matters

The older `ssh-rsa` key type may continue to work, but Ed25519 is the preferred
modern choice for new GitHub SSH keys. GitHub has restricted older or weaker
SSH algorithms over time.

This is a general developer-machine task, not an application deployment step.

## Safe migration order

Do not delete the existing RSA key first. Create and test the new key before
removing the old one.

### 1. Create an Ed25519 key

On macOS or Linux:

```sh
ssh-keygen -t ed25519 -C "your-github-email@example.com"
```

Use a descriptive filename if the default already exists, for example:

```text
~/.ssh/id_ed25519_github
```

Set a passphrase. Never share the private key file; only the file ending in
`.pub` belongs in GitHub.

### 2. Add the public key to GitHub

Copy the public key as one uninterrupted line:

```sh
pbcopy < ~/.ssh/id_ed25519_github.pub
```

In GitHub, open **Settings → SSH and GPG keys → New SSH key**, choose
**Authentication Key**, paste the contents, and save it.

### 3. Load the key into the macOS SSH agent

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github
```

If the key uses the default filename, replace the path with
`~/.ssh/id_ed25519`.

### 4. Test GitHub access

```sh
ssh -T git@github.com
```

A successful response identifies the authenticated GitHub account. Then test
the project repository from its local directory:

```sh
git fetch origin
git pull --ff-only
```

### 5. Remove the old RSA key later

After the Ed25519 key has worked successfully, remove the old RSA public key
from **GitHub → Settings → SSH and GPG keys**. Keep or securely delete the old
private key on the computer according to the organization’s device policy.

## Important safety rules

- Never paste a private key into GitHub, a ticket, chat, or the repository.
- Upload only the `.pub` file contents.
- The public key must remain on one line beginning with `ssh-ed25519`.
- Keep a working key until the replacement has been tested.
- A key passphrase protects the private key if the laptop is lost or copied.

GitHub’s current SSH guidance is available in its documentation:

<https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>
