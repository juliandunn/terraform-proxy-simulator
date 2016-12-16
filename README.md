# Proxy Simulator VPC in Terraform

It's often hard to simulate enterprise customers' complex proxy environments
for the purposes of debugging issues. This is a Terraform template that serves
to ease that burden, by setting up a fresh VPC with two subnets:
 
* 192.168.16.0/25 as a public subnet
* 192.168.16.128/25 as a private subnet

Network access control rules are further set up as follows:

* Egress to port 80/443 on the Internet is permitted from the public subnet
* Traffic on port 3128 between the public and private subnet is permitted
* No other traffic is permitted out of the private subnet

For convenience reasons, we allow direct SSH to instances on both the public
and private subnets.

## Machines

The Terraform template will set up two machines for you:

* One in the public subnet, with Squid running on port 3128
* One in the private subnet which you can use as a ChefDK workstation
  (ChefDK isn't installed though; you'll need to do that yourself)

On the workstation, a .bash_profile will be written out with the correct
`HTTP_PROXY`, `HTTPS_PROXY`, etc. environment variables already set up.

## Use Cases

You can use this setup for a few use cases:

* Use `kitchen` on your laptop and use the `kitchen-ec2 driver to create
  machines in the private subnet, forcing outgoing connections from Test
  Kitchen through the proxy. (In this case you won't use the ChefDK
  workstation)
* Use the Ubuntu ChefDK workstation to run `kitchen` directly.
* Any other situation you can think of that requires simulating proxies --
  create additional machines manually inside the private subnet as needed.

## Tips and Tricks

### I forgot the hostnames of the proxy server and/or workstation

Run `terraform output` and it'll print them out for you.

### .kitchen.yml settings for working with proxies using the `kitchen-ec2` driver

```yaml
---
driver:
  name: ec2
  security_group_ids: [ sg-deadbeef ]  # put the private security group here
  subnet_id: subnet-deadbeef # put the private subnet here
  aws_ssh_key_id: yourkey
  driver_config:
    http_proxy: http://ec2-xx-yy-zz-aa.compute-1.amazonaws.com:3128
    https_proxy: http://ec2-xx-yy-zz-aa.compute-1.amazonaws.com:3128

provisioner:
  name: chef_zero
  http_proxy: http://ec2-xx-yy-zz-aa.compute-1.amazonaws.com:3128
  https_proxy: http://ec2-xx-yy-zz-aa.compute-1.amazonaws.com:3128
```

(derived from Jeff Blaine's [excellent blog post](http://www.kickflop.net/blog/2015/10/28/using-test-kitchen-and-kitchen-vagrant-behind-an-http-proxy/))

### apt-get settings on the private workstation for installing things via proxy

Put the following in `/etc/apt/apt.conf` before `apt-get install` anything

```
Acquire::http::Proxy "http://ec2-xx-yy-zz-aa.compute-1.amazonaws.com:3128";
```

## using the proxy server from outside EC2

You can also use that proxy server from outside EC2 if you adjust the firewall
rules on the security group. You'll also need to update Squid's config
to allow access from your outgoing IP (it's a bad idea to allow the whole
world to access the Squid server 'cause that's a sure way to a) get DDoSsed
and b) have Amazon shut down your account :) )

After you do this you can set `HTTP_PROXY` and so on, on your laptop to
the proxy server's external IP.

## Author

* Julian C. Dunn (<jdunn@chef.io>)
