provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# VPC (basic, no segmentation)
# ----------------------------
resource "aws_vpc" "insecure_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.insecure_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.insecure_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

# ----------------------------
# Security Group (VERY INSECURE)
# ----------------------------
resource "aws_security_group" "insecure_sg" {
  name   = "insecure-sg"
  vpc_id = aws_vpc.insecure_vpc.id

  ingress {
    description = "Allow ALL traffic from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]   # ❌ Fully open
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------
# EC2 Instance (INSECURE CONFIG)
# ----------------------------
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 (example)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.insecure_sg.id]

  associate_public_ip_address = true

  # ❌ Hardcoded secrets + HTTP server
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              echo "DB_PASSWORD=SuperSecret123" >> /var/www/html/index.html
              echo "Welcome to insecure app" >> /var/www/html/index.html
              EOF

  tags = {
    Name = "insecure-web-app"
  }
}
