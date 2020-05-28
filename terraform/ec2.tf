variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
    default = "ap-northeast-1"
}


provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.aws_region}"
}
resource "aws_key_pair" "auth" {
    key_name    = "colonia_key"
    public_key  = file("/home/vagrant/.ssh/colonia_key.pub")
}

resource "aws_instance" "colonia" {
    ami           = "ami-f80e0596"
    instance_type = "t2.micro"
    monitoring    = true
    tags = {
        Name = "colonia"
    }
    key_name      = aws_key_pair.auth.id
    vpc_security_group_ids = [aws_security_group.colonia-sg.id]
}
