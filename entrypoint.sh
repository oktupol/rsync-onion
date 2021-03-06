#!/bin/bash

set -eu

# Set up ssh key
echo "$INPUT_SSH_PRIVATEKEY" > /tmp/id_ssh
chmod 600 /tmp/id_ssh

# Set up client authorization
if [[ -v "INPUT_ONION_CLIENT_AUTH_PRIVATEKEY" ]]; then
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
hosts_file="/tmp/known_hosts"
ssh_opts="-i /tmp/id_ssh -p $INPUT_SSH_PORT -o UserKnownHostsFile=$hosts_file"

# Strict host key checking
if [[ ( -v "INPUT_SSH_DISABLE_STRICT_HOST_KEY_CHECKING" ) && ( "$INPUT_SSH_DISABLE_STRICT_HOST_KEY_CHECKING" = "true" )]]; then
  ssh_opts="$ssh_opts -o StrictHostKeyChecking=accept-new"

  echo 'Strict host key checking disabled'
fi

# SSH Host fingerprint
if [[ ( -v "INPUT_SSH_HOST_FINGERPRINT" ) && ( -n "$INPUT_SSH_HOST_FINGERPRINT" ) ]]; then
  echo "$INPUT_SSH_HOST_FINGERPRINT" > $hosts_file
  
  echo 'Host key fingerprint provided'
fi

destination="$INPUT_SSH_USER@$INPUT_ONION_HOST.onion"

# Before command
if [[ ( -v "INPUT_BEFORE_RSYNC_COMMAND" ) && ( -n "$INPUT_BEFORE_RSYNC_COMMAND" ) ]]; then
  torsocks ssh $ssh_opts "$destination" "$INPUT_BEFORE_RSYNC_COMMAND"
  echo "Before command executed"
fi

# Actual file synchronisation
destination_dir="$destination:$INPUT_DESTINATION_DIR"
if [[ ( -v "INPUT_DELETE" ) && ( "$INPUT_DELETE" = "true" ) ]]; then
  torsocks rsync -rlptvz -e "ssh $ssh_opts" --delete "$INPUT_SOURCE_DIR" "$destination_dir"
else
  torsocks rsync -rlptvz -e "ssh $ssh_opts" "$INPUT_SOURCE_DIR" "$destination_dir"
fi
echo "Rsync finished"

# After command
if [[ ( -v "INPUT_AFTER_RSYNC_COMMAND" ) && ( -n "$INPUT_AFTER_RSYNC_COMMAND" ) ]]; then
  torsocks ssh $ssh_opts "$destination" "$INPUT_AFTER_RSYNC_COMMAND"
  echo "After command executed"
fi