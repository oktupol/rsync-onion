#!/bin/bash

set -eu

# Set up ssh key
echo "$INPUT_SSH_PRIVATEKEY" > /tmp/id_ssh
chmod 600 /tmp/id_ssh

# Set up client authorization
if [[ -n "$INPUT_ONION_CLIENT_AUTH_PRIVATEKEY" ]]; then
  authdir=/var/lib/tor/onion_auth
  echo "ClientOnionAuthDir $authdir" >> /etc/tor/torrc
  mkdir -p $authdir
  echo "$INPUT_ONION_HOST:descriptor:x25519:$INPUT_ONION_CLIENT_AUTH_PRIVATEKEY" \
    > $authdir/key.auth_private
  chown -R debian-tor $authdir
  
  echo 'Client Authorization enabled'
fi

# Start Tor
service tor start

# Set up ssh options
ssh_opts="ssh -i /tmp/id_ssh -p $INPUT_SSH_PORT"

# Strict host key checking
if [[ ( -n "$INPUT_SSH_DISABLE_STRICT_HOST_KEY_CHECKING" ) && ( "$INPUT_SSH_DISABLE_STRICT_HOST_KEY_CHECKING" = "true" )]]; then
  ssh_opts="$ssh_opts -o 'StrictHostKeyChecking=accept-new'"

  echo 'Strict host key checking disabled'
fi

# SSH Host fingerprint
if [[ -n "$SSH_HOST_FINGERPRINT" ]]; then
  hosts_file="/tmp/known_hosts"
  echo "$SSH_HOST_FINGERPRINT" > $hosts_file
  ssh_opts="$ssh_opts -o UserKnownHostsFile=$hosts_file"
  
  echo 'Host key fingerprint provided'
fi

# Actual file synchronisation
destination="$INPUT_SSH_USER@$INPUT_ONION_HOST.onion:$INPUT_DESTINATION_DIR"

if [[ ( -n "$INPUT_DELETE" ) && ( "$INPUT_DELETE" = "true" ) ]]; then
  torsocks rsync -rlptvz -e "$ssh_opts" --delete "$INPUT_SOURCE_DIR" "$destination"
else
  torsocks rsync -rlptvz -e "$ssh_opts" "$INPUT_SOURCE_DIR" "$destination"
fi
