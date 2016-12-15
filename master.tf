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
resource "aws_security_group" "proxy-vpc-public-subnet-sg" {
    name = "proxy-vpc-public-subnet-sg"
    description = "Ingress and egress rules for public subnet"
    vpc_id = "${aws_vpc.proxy-vpc.id}"
}

resource "aws_security_group_rule" "proxy-vpc-public-subnet-egress-http" {
    type = "egress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.proxy-vpc-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "proxy-vpc-public-subnet-egress-https" {
    type = "egress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.proxy-vpc-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "proxy-vpc-public-subnet-ingress-ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.proxy-vpc-public-subnet-sg.id}"
}

# Private subnet SG
resource "aws_security_group" "proxy-vpc-private-subnet-sg" {
    name = "proxy-vpc-private-subnet-sg"
    description = "Private subnet rules"
    vpc_id = "${aws_vpc.proxy-vpc.id}"
}

resource "aws_security_group_rule" "proxy-vpc-private-subnet-egress-squid" {
    type = "egress"
    from_port = 3128
    to_port = 3128
    protocol = "tcp"
    security_group_id = "${aws_security_group.proxy-vpc-private-subnet-sg.id}"
    source_security_group_id = "${aws_security_group.proxy-vpc-public-subnet-sg.id}"
}

resource "aws_security_group_rule" "proxy-vpc-private-subnet-ingress-ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.proxy-vpc-private-subnet-sg.id}"
}

# The proxy server
data "aws_ami" "fedora" {
  most_recent = true
  filter {
    name = "name"
    values = ["Fedora-Cloud-Base-25-*-HVM-standard-0"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["125523088429"] # Fedora
}

resource "aws_instance" "proxy-server" {
    ami = "${data.aws_ami.fedora.id}"
    instance_type = "${var.instance_size}"
    tags {
        Name = "proxy server"
    }
    key_name = "${lookup(var.keys, var.region)}"
    subnet_id = "${aws_subnet.proxy-vpc-public-subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.proxy-vpc-public-subnet-sg.id}"]
}
