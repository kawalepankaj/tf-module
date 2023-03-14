/* ...........................VPC....................................... */
resource "aws_vpc" "myvpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-myvpc"})
  #tags = merge(var.tags, { Name = format("%s-%s-myvpc", var.appname, var.env, ) })
}

/* ......................PUBLIC-SUBNET............................ */
resource "aws_subnet" "public" {
  count                   = length(var.public_cidr_block)
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_cidr_block[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = element(var.availability_zones, count.index)
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-public"})
}  

/* ......................PRIVATE-SUBNET............................ */
resource "aws_subnet" "private" {
  count             = length(var.private_cidr_block)
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.private_cidr_block[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-private"})
}

/* ......................IGW............................ */
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-igw"})
}  

/* ......................ELASTIC IP............................ */
resource "aws_eip" "eip" {
  vpc      = true
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-eip"})
}

/* ......................NAT GATEWAY............................ */
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-nat"})
}

/* ......................PUBLIC-ROUTE-TABLE............................ */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-public-RT"})
}  

/* ......................PRIVATE-ROUTE-TABLE............................ */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = merge(var.tags, {Name = "${var.appname}-${var.env}-private-RT"})
}  

/* ......................PUBLIC-SUBNET-ASSOCIATION............................ */
resource "aws_route_table_association" "public" {
  count          = length(var.public_cidr_block)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

/* ......................PRIVATE-SUBNET-ASSOCIATION............................ */
resource "aws_route_table_association" "private" {
  count          = length(var.private_cidr_block)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

/* ......................SECURITY-GROUP............................ */
resource "aws_security_group" "my-sg" {
  name        = "my-sg"
  description = "my-sg inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "LB-SG"
  }
}