#!/bin/bash

GITHUB_KEYS="https://github.com/torvaldss.keys"
KEYS_FILE="/tmp/github_keys.tmp"
SSHD_CONFIG="/etc/ssh/sshd_config"

curl -fsSL "$GITHUB_KEYS" -o "$KEYS_FILE"

if [ ! -s "$KEYS_FILE" ]; then
    echo "Не удалось загрузить ключи"
    exit 1
fi

mkdir -p ~/.ssh
cat "$KEYS_FILE" >> ~/.ssh/authorized_keys
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

rm -f /etc/ssh/sshd_config.d/01-delonix.conf

grep -q "^PasswordAuthentication" $SSHD_CONFIG && sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication no/' $SSHD_CONFIG || echo "PasswordAuthentication no" >> $SSHD_CONFIG

grep -q "^PermitRootLogin" $SSHD_CONFIG && sed -i 's/^.*PermitRootLogin.*/PermitRootLogin prohibit-password/' $SSHD_CONFIG || echo "PermitRootLogin prohibit-password" >> $SSHD_CONFIG

grep -q "^PubkeyAuthentication" $SSHD_CONFIG && sed -i 's/^.*PubkeyAuthentication.*/PubkeyAuthentication yes/' $SSHD_CONFIG || echo "PubkeyAuthentication yes" >> $SSHD_CONFIG

grep -q "^ChallengeResponseAuthentication" $SSHD_CONFIG && sed -i 's/^.*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' $SSHD_CONFIG || echo "ChallengeResponseAuthentication no" >> $SSHD_CONFIG

grep -q "^UsePAM" $SSHD_CONFIG && sed -i 's/^.*UsePAM.*/UsePAM no/' $SSHD_CONFIG || echo "UsePAM no" >> $SSHD_CONFIG

grep -q "^PermitEmptyPasswords" $SSHD_CONFIG && sed -i 's/^.*PermitEmptyPasswords.*/PermitEmptyPasswords no/' $SSHD_CONFIG || echo "PermitEmptyPasswords no" >> $SSHD_CONFIG

sshd -t

if [ $? -eq 0 ]; then
    systemctl restart sshd
    echo "Готово"
else
    echo "Ошибка в конфигурации"
    exit 1
fi

rm -f "$KEYS_FILE"
