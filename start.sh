#!/bin/sh

# Create or update git user with configurable PUID/PGID
echo "Setting up git user with PUID=${PUID} and PGID=${PGID}"

# Create group if it doesn't exist
if ! getent group git > /dev/null 2>&1; then
  addgroup -g ${PGID} git
else
  # Update GID if it's different
  CURRENT_GID=$(getent group git | cut -d: -f3)
  if [ "${CURRENT_GID}" != "${PGID}" ]; then
    groupmod -g ${PGID} git
  fi
fi

# Create user if it doesn't exist
if ! id git > /dev/null 2>&1; then
  adduser -D -u ${PUID} -G git -s /usr/bin/git-shell git
  echo git:12345 | chpasswd
else
  # Update UID if it's different
  CURRENT_UID=$(id -u git)
  if [ "${CURRENT_UID}" != "${PUID}" ]; then
    usermod -u ${PUID} git
  fi
  # Ensure user is in correct group and has correct shell
  usermod -g ${PGID} -s /usr/bin/git-shell git
fi

# Ensure home directory and .ssh directory exist with proper permissions
mkdir -p /home/git/.ssh
chown -R git:git /home/git
chmod 700 /home/git/.ssh

# If there is some public key in keys folder
# then it copies its contain in authorized_keys file
if [ "$(ls -A /git-server/keys/)" ]; then
  cd /home/git
  cat /git-server/keys/*.pub > .ssh/authorized_keys
  chown -R git:git .ssh
  chmod 700 .ssh
  chmod -R 600 .ssh/*
fi

# Checking permissions and fixing SGID bit in repos folder
# More info: https://github.com/jkarlosb/git-server-docker/issues/1
if [ "$(ls -A /git-server/repos/)" ]; then
  cd /git-server/repos
  chown -R git:git .
  chmod -R ug+rwX .
  find . -type d -exec chmod g+s '{}' +
fi

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D
