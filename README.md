# Proxy Simulator VPC

This Terraform setup sets up a VPC with two subnets, one of which has a route
to the Internet, and the other which does not, only a route to the public
subnet.

Inside the public subnet there is a proxy server set up running Squid.

This harness is useful for testing out customer scenarios with proxies.
