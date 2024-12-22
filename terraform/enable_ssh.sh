#!/bin/bash
until ping -4 -c 1 google.com &> /dev/null # wait for dns
do
  sleep 1
done


dnf -y install openssh-server > /dev/null
systemctl enable --now sshd > /dev/null