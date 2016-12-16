#!/bin/sh

echo 'export http_proxy="http://${proxy_server}:3128"' >> ~ubuntu/.bash_profile
echo 'export https_proxy="http://${proxy_server}:3128"' >> ~ubuntu/.bash_profile
echo 'export HTTPS_PROXY="http://${proxy_server}:3128"' >> ~ubuntu/.bash_profile
echo 'export HTTPS_PROXY="http://${proxy_server}:3128"' >> ~ubuntu/.bash_profile
chown ubuntu:ubuntu ~ubuntu/.bash_profile
