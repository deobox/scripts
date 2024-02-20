#!/usr/bin/env bash
apt install -f -y libpam-google-authenticator;
echo "#Google Authenticator" >> /etc/pam.d/sshd;
echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd;
sed -i 's|KbdInteractiveAuthentication|#KbdInteractiveAuthentication|g' /etc/ssh/sshd_config;
echo "#Google Authenticator" >> /etc/ssh/sshd_config;
echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config;
echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config;
