provider "aws" {
    region = "${var.region}"
}

# VPC and basic networking
resource "aws_vpc" "proxy-vpc" {
    cidr_block = "192.168.16.0/24"
    enable_dns_hostnames = true
    tags {
        Name = "proxy-vpc"
    }
}

resource "aws_internet_gateway" "proxy-vpc-igw" {
    vpc_id = "${aws_vpc.proxy-vpc.id}"

    tags {
        Name = "proxy-vpc-igw"
    }
}

resource "aws_subnet" "proxy-vpc-public-subnet" {
    vpc_id = "${aws_vpc.proxy-vpc.id}"
    cidr_block = "192.168.16.0/25"
    map_public_ip_on_launch = true

    tags {
        Name = "proxy-vpc-public"
    }
}

resource "aws_subnet" "proxy-vpc-private-subnet" {
    vpc_id = "${aws_vpc.proxy-vpc.id}"
    cidr_block = "192.168.16.128/25"

    tags {
        Name = "proxy-vpc-private"
    }
}

resource "aws_route_table" "proxy-vpc-outbound" {
    vpc_id = "${aws_vpc.proxy-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.proxy-vpc-igw.id}"
    }

    tags {
        Name = "proxy-vpc-default-route"
    }
}

resource "aws_route_table_association" "proxy-vpc-public-routing" {
    subnet_id = "${aws_subnet.proxy-vpc-public-subnet.id}"
    route_table_id = "${aws_route_table.proxy-vpc-outbound.id}"
}

# Only allow the public subnet group to access ports 80 and 443
resource "aws_security_group" "proxy-vpc-egress-sg" {
    name = "proxy-vpc-egress-sg"
    description = "Egress rules from public subnet - HTTP and HTTPS only"
    vpc_id = "${aws_vpc.proxy-vpc.id}"
}

resource "aws_security_group_rule" "public-subnet-egress-http" {
    type = "egress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_group_id = "${aws_security_group.proxy-vpc-egress-sg.id}"
}

resource "aws_security_group_rule" "public-subnet-egress-https" {
    type = "egress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_group_id = "${aws_security_group.proxy-vpc-egress-sg.id}"
}

resource "aws_security_group_rule" "public-subnet-egress-squid" {
    type = "egress"
    from_port = 3128
    to_port = 3128
    protocol = "tcp"
    security_group_id = "${aws_security_group.proxy-vpc-egress-sg.id}"
}

# Create a security group that allows us to directly SSH to any instance
resource "aws_security_group" "proxy-vpc-ingress-ssh-sg" {
    name = "proxy-vpc-ingress-ssh-sg"
    description = "Ingress rules from anywhere - SSH only"
    vpc_id = "${aws_vpc.proxy-vpc.id}"
}

resource "aws_security_group_rule" "proxy-vpc-ingress-ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_group_id = "${aws_security_group.proxy-vpc-ingress-ssh-sg.id}"
}

# Group to allow ingress from the machines SG to the proxy SG
resource "aws_security_group" "proxy-vpc-proxied-sources-sg" {
    name = "proxy-vpc-proxied-sources-sg"
    description = "Allow egress from this SG to the proxy-vpc-egress-sg"
    vpc_id = "${aws_vpc.proxy-vpc.id}"
}

resource "aws_security_group_rule" "private-subnet-egress-squid" {
    type = "egress"
    from_port = 3128
    to_port = 3128
    protocol = "tcp"
    security_group_id = "${aws_security_group.proxy-vpc-egress-sg.id}"
    source_security_group_id = "${aws_security_group.proxy-vpc-proxied-sources-sg.id}"
}
