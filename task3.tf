provider "aws" {
  region     = "ap-south-1"
  profile    = "default"
}



resource "tls_private_key" "UDIT" {
    algorithm = "RSA"
}


resource "local_file" "private_key" {
    content         =   tls_private_key.UDIT.private_key_pem
    filename        =   "mykey1.pem"
}


resource "aws_key_pair" "mykey1" {
    key_name   = "mykey_1"
    public_key = tls_private_key.UDIT.public_key_openssh
}




resource "aws_vpc" "MyFirstVPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  
  tags = {
    Name = "uditanshuvpc"
  }
}


resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.MyFirstVPC.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "publicsubnet"
  }
}



resource "aws_subnet" "privatesubnet" {
  vpc_id     = aws_vpc.MyFirstVPC.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "privatesubnet"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.MyFirstVPC.id

  tags = {
    Name = "gateway"
  }
}



resource "aws_route_table" "routetable1" {
  vpc_id = aws_vpc.MyFirstVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "routetable"
  }
}





resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.routetable1.id
}


resource "aws_security_group" "Allow_Traffic_wp" {
  depends_on = [ aws_vpc.MyFirstVPC ]
  name        = "Security_Guard_WP"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.MyFirstVPC.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
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
    Name = "Security_Guard_WP"
  }
}



resource "aws_security_group" "Allow_Traffic_mysql" {
  depends_on = [ aws_vpc.MyFirstVPC ]
  name        = "Security_Guard_MMYSQL"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.MyFirstVPC.id

  ingress {
    description = "MYSQL vpc"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Allow_Traffic_wp.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Security_Guard_MYSQL"
  }
}



resource "aws_instance" "FIRST_WP_OS" {
  ami           = "ami-7e257211"
  instance_type   = "t2.micro"
  key_name  =  aws_key_pair.mykey1.key_name
  security_groups  = [aws_security_group.Allow_Traffic_wp.id]
  subnet_id = aws_subnet.publicsubnet.id

  tags = {
      Name = "WordPressOS"
    }
}



resource "aws_instance" "FIRST_MYSQL_OS" {
  ami           = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  key_name  =  aws_key_pair.mykey1.key_name
  security_groups  = [aws_security_group.Allow_Traffic_mysql.id]
  subnet_id = aws_subnet.privatesubnet.id

  tags = {
      Name = "MYSQLDB"
    }
}

