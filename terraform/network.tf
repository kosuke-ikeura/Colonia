resource "aws_vpc" "colonia-vpc" {
    cidr_block              = "10.0.0.0/16"
    instance_tenancy        = "default"
    enable_dns_support      = true
    enable_dns_hostnames    = true
    tags = {
        Name = "colonia-vpc"
    }
}

resource "aws_subnet" "colonia_public_0" {
    vpc_id                  = aws_vpc.colonia-vpc.id
    cidr_block              = "10.0.3.0/24"
    availability_zone       = "ap-northeast-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "colonia_public_0"
    }
}

resource "aws_subnet" "colonia_public_1" {
    vpc_id                  = aws_vpc.colonia-vpc.id
    cidr_block              = "10.0.4.0/24"
    availability_zone       = "ap-northeast-1c"
    map_public_ip_on_launch = true
    tags = {
        Name = "colonia_public_1"
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

resource "aws_route_table_association" "public_0" {
    subnet_id       = aws_subnet.colonia_public_0.id
    route_table_id  = aws_route_table.public.id
}
resource "aws_route_table_association" "public_1" {
    subnet_id       = aws_subnet.colonia_public_1.id
    route_table_id  = aws_route_table.public.id
}

# プライベートサブネットの定義(マルチAZ)
resource "aws_subnet" "private_0" {
    vpc_id                  = aws_vpc.colonia-vpc.id
    cidr_block              = "10.0.67.0/24"
    availability_zone       = "ap-northeast-1a"
    map_public_ip_on_launch = false  
}
resource "aws_subnet" "private_1" {
    vpc_id                  = aws_vpc.colonia-vpc.id
    cidr_block              = "10.0.68.0/24"
    availability_zone       = "ap-northeast-1c"
    map_public_ip_on_launch = false
}

# プライベートルートテーブルとvpcとの関連付けの定義
resource "aws_route_table" "private_0" {
    vpc_id = aws_vpc.colonia-vpc.id
}
resource "aws_route_table" "private_1" {
    vpc_id = aws_vpc.colonia-vpc.id
}
# プライベートのルートの定義(マルチAZ)
resource "aws_route" "private_0" {
    route_table_id          = aws_route_table.private_0.id
    nat_gateway_id          = aws_nat_gateway.nat_gateway_0.id
    destination_cidr_block  = "0.0.0.0/0"
}
resource "aws_route" "private_1" {
    route_table_id          = aws_route_table.private_1.id
    nat_gateway_id          = aws_nat_gateway.nat_gateway_1.id
    destination_cidr_block  = "0.0.0.0/0"
}
# プライベートルートテーブルとサブネットの関連付けの定義(マルチAZ)
resource "aws_route_table_association" "private_0" {
    subnet_id       = aws_subnet.private_0.id
    route_table_id  = aws_route_table.private_0.id
}
resource "aws_route_table_association" "private_1" {
    subnet_id       = aws_subnet.private_1.id
    route_table_id  = aws_route_table.private_1.id
}

# EIPの定義(マルチAZ)
resource "aws_eip" "nat_gateway_0" {
    vpc           = true
    depends_on    = [aws_internet_gateway.colonia]
}
resource "aws_eip" "nat_gateway_1" {
    vpc           = true
    depends_on    = [aws_internet_gateway.colonia]
}

# NATゲートウェイの定義(マルチAZ)
resource "aws_nat_gateway" "nat_gateway_0" {
    allocation_id = aws_eip.nat_gateway_0.id
    subnet_id     = aws_subnet.colonia_public_0.id
    depends_on    = [aws_internet_gateway.colonia]
}
resource "aws_nat_gateway" "nat_gateway_1" {
    allocation_id = aws_eip.nat_gateway_1.id
    subnet_id     = aws_subnet.colonia_public_1.id
    depends_on    = [aws_internet_gateway.colonia]
}

resource "aws_security_group" "colonia-sg" {
    name   = "colonia-ec2-sg"
    vpc_id = aws_vpc.colonia-vpc.id
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