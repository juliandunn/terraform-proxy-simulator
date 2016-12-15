variable "region" {
    default = "us-east-1"
}

variable "keys" {
    default = {
        us-east-1 = "us-east1-jdunn"
        us-east-2 = "us-east2-jdunn"
        us-west-1 = "us-west1-jdunn"
        us-west-2 = "us-west2-jdunn"
    }
}

variable "instance_size" {
    default = "t2.small"
}
