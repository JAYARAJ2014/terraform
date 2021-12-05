
### Define a set of vars. Values will be provided in tfvars file
variable "default_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
variable "default_az" {
  type    = string
  default = "us-east-1a"
}
variable "access_key" {
  type = string
}
variable "secret_key" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "warning_tag" {
  type    = string
  default = "Created by terraform. Dont alter or delete"
}

# module where no explicit provider instance is selected.
provider "aws" {
  region     = var.default_region
  access_key = var.access_key
  secret_key = var.secret_key
}


### 1. Create a VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    "Name"  = "prod_vpc",
    Warning = var.warning_tag

  }
}
### 2. Create an Internet Gateway
resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name    = "prod_igw",
    Warning = var.warning_tag
  }
}

### 3. Create a Custom Route Table
resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.prod_igw.id
  }

  tags = {
    Name    = "prod_route_table",
    Warning = var.warning_tag
  }
}
### 4. Create a subnet
resource "aws_subnet" "prod_vpc_subnet_1" {

  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.default_az
  tags = {
    Name             = "prod_vpc_subnet_1",
    AvailabilityZone = var.default_az,
    Warning          = var.warning_tag
  }
}

### 5. Associate the subnet from Step 4 with a Route Table 
### This resource cannot have a tag as its just an association
resource "aws_route_table_association" "prod_vpc_subnet_1_to_prod_route_table" {
  subnet_id      = aws_subnet.prod_vpc_subnet_1.id
  route_table_id = aws_route_table.prod_route_table.id
}

### 6. Create a Security Group to allow ports 22,80 and 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "allow_web",
    Warning = var.warning_tag
  }
}

### 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.prod_vpc_subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  tags = {
    Name    = "web_server_nic",
    Warning = var.warning_tag
  }
}

### 8. Assign Elastic IP to the Network Interface created in Step 7
### IGW should be deployed first.
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.prod_igw]
  tags = {
    Name    = "one",
    Warning = var.warning_tag
  }
}

### 9. Create an Ubuntu server and install/enable Apache2
## Availability zone should be in the same AZ as the subnet
resource "aws_instance" "web_server_instance" {
  ami               = "ami-083654bd07b5da81d"
  instance_type     = "t2.micro"
  availability_zone = var.default_az
  key_name          = "main-key"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_nic.id
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo hellow worldd > /var/www/html/index.html'
            EOF

  tags = {
    Name    = "web_server_instance",
    Warning = var.warning_tag
  }
}

### 10. Output properties of resources created.
output "Region" {
  value = var.default_region
}
output "AZ" {
  value = var.default_az
}
output "Web_Server_Public_IP" {
  value = aws_eip.one.public_ip
}
output "Web_Server_Public_DNS" {
  value = aws_eip.one.public_dns
}
