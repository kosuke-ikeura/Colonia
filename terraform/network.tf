resource "aws_vpc" "colonia-vpc" {
    cidr_block              = "10.0.0.0/16"
    instance_tenancy        = "default"
    enable_dns_support      = true
    enable_dns_hostnames    = true
    tags = {
        Name = "colonia-vpc"
    }
}

resource "aws_subnet" "colonia_public" {
    vpc_id                  = aws_vpc.colonia-vpc.id
    cidr_block              = "10.0.0.0/24"
    availability_zone       = "ap-northeast-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "colonia_public"
    }
}

resource "aws_internet_gateway" "colonia" {
    vpc_id = aws_vpc.colonia-vpc.id
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.colonia-vpc.id
}

resource "aws_route" "public" {
    route_table_id          = aws_route_table.public.id
    gateway_id              = aws_internet_gateway.colonia.id
    destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
    subnet_id       = aws_subnet.colonia_public.id
    route_table_id  = aws_route_table.public.id
}

resource "aws_security_group" "colonia-sg" {
    egress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks  = [
            "0.0.0.0/0"
        ]
    }
    tags = {
        Name = "colonia-sg"
    }
}

resource "aws_security_group_rule" "inbound_http" {
    security_group_id = aws_security_group.colonia-sg.id
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = [
        "0.0.0.0/0"
    ]
}

resource "aws_security_group_rule" "inbound_ssh" {
    security_group_id = aws_security_group.colonia-sg.id
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = [
        "0.0.0.0/0"
    ]
}
