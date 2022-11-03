locals {
    N_public_subs = floor(var.N_subnets/2)
    N_private_subs = (var.N_subnets%2) + local.N_public_subs
    region_list = [
        "us-east-1a",
        "us-east-1b",
        "us-east-1c",
        "us-east-1d",
        "us-east-1e",
        "us-east-1f"
    ]
    region_az = slice(local.region_list,0,floor(var.N_subnets/2))
}

resource "aws_vpc" "main_vpc" {
    cidr_block = var.Network_CIDR
    tags = merge(var.Tags,{
        Name = "vpc_${var.Name}"
    })
}

resource "aws_subnet" "vpc_subnets" {
    count = var.N_subnets
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block,4,count.index + 1)
    availability_zone = element(local.region_az,count.index)
    tags = merge(var.Tags,{
        Name = (count.index <= local.N_public_subs - 1 ? "public_${var.Name}_${count.index + 1}" : "private_${var.Name}_${count.index + 1}")
    })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(var.Tags,{
        Name = "igw_${var.Name}"
  })
}


resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge(var.Tags,{
    Name = "public_rtb_${var.Name}"
  })
}

resource "aws_route_table_association" "public_association_subnet" {
    count = local.N_public_subs
    subnet_id      = element(aws_subnet.vpc_subnets, count.index).id
    route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route" "public_igw" {
  route_table_id            = aws_route_table.public_rtb.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
  depends_on                = [aws_route_table.public_rtb]
}


resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge(var.Tags,{
    Name = "private_rtb_${var.Name}"
  })
}

resource "aws_route_table_association" "private_association_subnet" {
    count = local.N_private_subs
    subnet_id      = element(aws_subnet.vpc_subnets, count.index + local.N_public_subs).id
    route_table_id = aws_route_table.private_rtb.id
}


resource "aws_eip" "nat_gateway_eip" {
  vpc      = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = merge(var.Tags,{
    Name = "nat_gw_eip_${var.Name}"
  })
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.vpc_subnets[0].id
  tags = merge(var.Tags,{
    Name = "nat_gw_${var.Name}"
  })
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route" "private_nat_gw" {
  route_table_id            = aws_route_table.private_rtb.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw.id
  depends_on                = [aws_route_table.private_rtb,aws_route_table.public_rtb,aws_nat_gateway.nat_gw]
}
