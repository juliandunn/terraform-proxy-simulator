#!/bin/sh

echo 'export HTTP_PROXY="http://${proxy_server}:3128"' >> ~ubuntu/.bash_profile
echo 'export HTTPS_PROXY="http://${proxy_server}:3128"' >> ~ubuntu/.bash_profile
