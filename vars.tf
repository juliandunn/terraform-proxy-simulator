variable "region" {
    default = "us-east-1"
}

variable "amis" {
    default = {
        us-east-1 = "ami-6d1c2007"
        us-west-1 = "ami-6bcfc42e"
        us-west-2 = "ami-c7d092f7"
    }
}

variable "keys" {
    default = {
        us-east-1 = "us-east1-jdunn"
        us-west-1 = "us-west1-jdunn"
        us-west-2 = "us-west2-jdunn"
    }
}

variable "instance_size" {
    default = "t2.small"
}
