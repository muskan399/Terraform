// Accessing account
//In this profile our login details are present. We have created this profile using CMD.
provider "aws" {
  region= "ap-south-1"
  profile="muskan"
}

//Creating our own VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "task-vpc"
  }
}

//Creating public subnet
resource "aws_subnet" "sub1" {
  vpc_id     = "${aws_vpc.main.id}"
  availability_zone ="ap-south-1a"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
  depends_on=[aws_vpc.main,]
}

//Creating private subnet
resource "aws_subnet" "sub2" {
  vpc_id     = "${aws_vpc.main.id}"
  availability_zone ="ap-south-1b"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "private-subnet"
  }
  depends_on=[aws_vpc.main,]
}

//Creating Internet gateway for SNAT and DNAT
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "ig"
  }
  depends_on=[aws_vpc.main,]
}

//Security group for instance in public world here wordpress
resource "aws_security_group" "public" {
  name        = "sg1-wp"
  description = "Allow SSH,HTTP"
  vpc_id      = "${aws_vpc.main.id}"
  depends_on=[aws_vpc.main,]

  ingress {
    description = "Allowing SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "Allowing ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allowing HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allowing HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allowing for Patting"
    from_port   = 8200
    to_port     = 8200
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
    Name = "sg1-wp"
  }
}

//Creating Security group for MySQL
//We want wp to act as bastion host for that we added a rule and allowing the instances with wp security group/
resource "aws_security_group" "private" {
  name        = "sg2-mysql"
  description = "Allow 3306"
  vpc_id      = "${aws_vpc.main.id}"
  depends_on=[aws_vpc.main,aws_security_group.public]

  ingress {
    description = "Allowing mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.public.id}"]
  }

   ingress {
    description = "Allowing SSH(Bastion Host)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.public.id}"]
  }

  ingress {
    description = "Allowing ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg2-mysql"
  }
}

//Creating Key
resource "tls_private_key" "task4_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "task4_key"
  
  //Using unique id of above

  public_key = "${tls_private_key.task4_key.public_key_openssh}"
}
output "wp_private_key" {
value=tls_private_key.task4_key.private_key_pem
}

//Creating WP instance
resource "aws_instance" "wp" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.public.id}"]
  subnet_id = "${aws_subnet.sub1.id}"
  associate_public_ip_address = true
  tags = {
    Name = "wp"
  }
  provisioner "remote-exec"{
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${tls_private_key.task4_key.private_key_pem}"
    host     = aws_instance.wp.public_ip
  }
    inline =[
      "sudo yum install docker -y",
      "sudo systemctl start docker",
      "sudo docker run -dit --name wp -p 8200:80 -e WORDPRESS_DB_HOST=${aws_instance.mysql.private_ip}:3306 -e WORDPRESS_DB_USER=muskan -e WORDPRESS_DB_PASSWORD=redhat -e WORDPRESS_DB_NAME=wp-database wordpress:5.1.1-php7.3-apache",
     
    
    ]

}
  depends_on=[aws_vpc.main,aws_key_pair.generated_key,aws_instance.mysql]
}
output "public_ip" {
value=aws_instance.wp.public_ip
}


//Creating MySQL instance
resource "aws_instance" "mysql" {
  ami           = "ami-0ebc1ac48dfd14136"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids= ["${aws_security_group.private.id}"]
  subnet_id = "${aws_subnet.sub2.id}"
  associate_public_ip_address = false
  user_data = <<EOF
		 #! /bin/bash
     sudo yum install docker -y
		 sudo systemctl start docker
		 sudo docker run --name wp-mysql -e MYSQL_ROOT_PASSWORD=redhat -e MYSQL_USER=muskan -e MYSQL_PASSWORD=redhat -e MYSQL_DATABASE=wp-database -p 3306:3306 -d mysql:5.7
  EOF
  
  tags = {
    Name = "mysql"
  }
  depends_on=[aws_vpc.main,aws_key_pair.generated_key]
}
output "mysql_private_ip" {
value=aws_instance.mysql.private_ip
}



//Creating route table for public subnet
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "route-table-public"
  }
depends_on=[aws_vpc.main, aws_internet_gateway.gw]
}

//Associating with public subnet.
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.r.id
   depends_on=[aws_subnet.sub1, aws_route_table.r]
}

//Creating EIP for NAT gw
resource "aws_eip" "lb" {
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.sub1.id

  tags = {
    Name = "gw NAT"
  }
depends_on=[aws_subnet.sub1, aws_eip.lb]
}

//Routing table for private subnet
resource "aws_route_table" "r1" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags = {
    Name = "route-table-private"
  }
depends_on=[aws_vpc.main,aws_nat_gateway.gw]
}

//Associating with private subnet.
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.r1.id
depends_on=[aws_subnet.sub2, aws_route_table.r1]
}


