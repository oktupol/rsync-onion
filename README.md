# 🚀 Rsync to Onion Service for GitHub Actions

[Github Action](https://github.com/features/actions) for copying files and
artifacts via Rsync to an Onion service.

## Usage

Copy files and artifacts via Rsync:

```yaml
name: Rsync files
on: [push]

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Rsync to Onion
        uses: oktupol/rsync-onion@master
        with:
          source_dir: ./dist/
          destination_dir: /var/www/htdocs
          ssh_user: ${{ secrets.SSH_USER }}
          ssh_privatekey: ${{ secrets.SSH_PRIVATEKEY }}
          onion_host: ${{ secrets.ONION_HOST }}
          onion_client_auth_privatekey: ${{ secret.ONION_CLIENT_AUTH_PRIVATEKEY}}
          delete: true
```

## Input variables:

### Required variables

- `source_dir` - Source directory in the Workflow.
- `destination_dir` - Destination dir on the remote onion service.
- `ssh_user` - SSH username for remote authentication.
- `ssh_privatekey` - SSH private key for remote authentication. Currently, only
  keys without passphrases are supported.
- `onion_host` - The hostname of the onion service _WITHOUT_ the `.onion`
  suffix.  
  For `duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion`, this
  would therefore be `duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad`.

### Optional variables

- `ssh_port` - SSH port. Default: 22
- `onion_client_auth_privatekey` - Private key for [Client
  Authorization](https://community.torproject.org/onion-services/advanced/client-auth/).
  If enabled in the onion service, this value is required.
- `delete` - Set this to `true` to delete extraneous files from the destination dir.
  
Currently, no password authentication is supported.

## Use Case

Let's say you're running a Reddit bot or Discord bot on a Raspberry Pi in your home and want to update it automatically on every push to a repository, without having to do any of the following:

- Periodically polling for changes
- Opening and forwarding a port on your home router, potentially exposing your device to attackers.
- Setting up DynDNS or similar if your home network doesn't have a static IP address.

Instead, you set up an SSH server and an
[onion service](https://community.torproject.org/onion-services/setup/) on the
same port, allowing you to SSH into your Raspberry Pi from anywhere over Tor.
The way onion services function allows them to be reachable even behind NAT
setups and firewalls.

I recommend setting up
[Client Authorization](https://community.torproject.org/onion-services/advanced/client-auth/)
as well. That way, even if someone other than you found out your device's onion
url, they wouldn't be able to resolve and connect to it due to not having the
correct private key.

This action is intended for people who want to upload files onto a remote
server based on a Workflow, without having to expose it to the "open" Internet.
If you're running a web server, this is probably a bit excessive, since your
web server is either not managed by yourself, or already known to public (or
both). But if you are running a hobby project on a home computer, this might be
for you.

## <small>(This is not a)</small> Legal advice

It shouldn't be necessary to state the obvious: **Do not use this for uploading
files to your illegal site on the Dark Web**. Using this action _will_ link
your onion service with your Github username. This action is primarily an
utility for hobby projects. Privacy and anonymity were not considered while
creating it.