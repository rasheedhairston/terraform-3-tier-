# VPC Resource
resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "luit-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "luit-internet-gateway"
  }
}


# Public Subnet 
resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_cidr
  map_public_ip_on_launch = true


  tags = {
    Name = "luit-pub-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.private_cidr

  tags = {
    Name = "luit-private-subnet"
  }
}

# Database Subnet
resource "aws_subnet" "database_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block        = var.database_cidr

  tags = {
    Name = "luit-dta-subnet"
  }
}

# Route Table 
resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "my-public-subnet-route-table"
  }
}

# Public subnet route table association
resource "aws_route_table_association" "public_subnet_route_table_association" {
    subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

# bastion - EC2 Instance Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "ec2-sg"
  description = "Allowing requests to the ec2"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "luit-security-group"
  }
}

# bastian - Launch Template
resource "aws_launch_template" "bastion_template" {
  name_prefix   = "luit-template"
  image_id      = "ami-0022f774911c1d690"
  instance_type = "t2.micro"
}

# bastion - Auto Scaling Group
resource "aws_autoscaling_group" "bastion_asg" {
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  vpc_zone_identifier = [aws_subnet.my_public_subnet.id]
 
  launch_template {
    id      = aws_launch_template.bastion_template.id
    version = "$Latest"
  }
}

# private - EC2 Instance Security Group
resource "aws_security_group" "app_instance_sg" {
  name        = "private-security-group"
  description = "Allowing requests to the app servers"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
   
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-server-security-group"
  }
}

# private - Launch Template
resource "aws_launch_template" "private_template" {
  name_prefix   = "private-template"
  image_id      = "ami-0022f774911c1d690"
  instance_type = "t2.micro"
  
}

# private - Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.private_subnet.id]

  launch_template {
    id      = aws_launch_template.private_template.id
    version = "$Latest"
  }
}

# DB - Security Group
resource "aws_security_group" "db_security_group" {
  name = "mydb1"

  description = "RDS postgres server"
  vpc_id = aws_vpc.my_vpc.id

  # Only postgres in
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB - Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.database_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# DB - RDS Instance
resource "aws_db_instance" "db_postgres" {
  allocated_storage        = 256 # gigabytes
  backup_retention_period  = 7   # in days
  db_subnet_group_name     = aws_db_subnet_group.db_subnet.id
  engine                   = "postgres"
  identifier               = "dbpostgres"
  instance_class           = "db.t3.micro"
  multi_az                 = false
  name                     = "dbpostgres"
  username                 = "dbadmin"
  password                 = "set-your-own-password!"
  port                     = 5432
  publicly_accessible      = false
  storage_encrypted        = true
  storage_type             = "gp2"
  vpc_security_group_ids   = [aws_security_group.db_security_group.id]
  skip_final_snapshot      = true
}
