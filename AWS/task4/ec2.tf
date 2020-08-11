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

