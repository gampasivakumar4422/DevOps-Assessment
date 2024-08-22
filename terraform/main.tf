# Define AWS Provider
provider "aws" {
  region = "us-west-2"
}

# VPC Setup
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-igw"
  }
}

# Subnet 1 in Availability Zone 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"  # Updated CIDR block to avoid conflict
  availability_zone = "us-west-2a"   # Adjust according to your region

  tags = {
    Name = "Public Subnet 1"
  }
}

# Subnet 2 in Availability Zone 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"  # Updated CIDR block to avoid conflict
  availability_zone = "us-west-2b"   # Adjust according to your region

  tags = {
    Name = "Public Subnet 2"
  }
}


# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}
# Route Table Association for Subnet 1
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id   # Update this to the correct subnet
  route_table_id = aws_route_table.public_rt.id
}

# Route Table Association for Subnet 2
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id   # Update this to the second subnet
  route_table_id = aws_route_table.public_rt.id
}

