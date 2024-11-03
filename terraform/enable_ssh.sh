#!/bin/bash
dnf -y install openssh-server
systemctl enable --now sshd