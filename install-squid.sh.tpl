#!/bin/sh

dnf -y install squid
# In here you'd want to config the squid template but the default is good enough for now
systemctl enable squid.service
systemctl start squid.service
