//Account Access
provider "aws" {
  region= "ap-south-1"
  profile="muskan"
}

resource "aws_security_group" "terrasg1" {

  name        = "terrasg1"
  description = "allow ssh and http traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "terrasg2" {

  name        = "terrasg2"
  description = "allow nfs"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  
}
resource "tls_private_key" "terrakey-new" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terrakey-new"
  
  //Using unique id of above

  public_key = "${tls_private_key.terrakey-new.public_key_openssh}"
}
output "out2" {
value=tls_private_key.terrakey-new.private_key_pem
}
resource "aws_instance" "terraos-new1" {
  ami               = "ami-5b673c34"
  instance_type     = "t2.micro"
  security_groups   = ["${aws_security_group.terrasg1.name}"]
  key_name = "terrakey-new"
  provisioner "remote-exec" {
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("C:/Users/muska/Downloads/terrakey-new.pem")}"
    host     = aws_instance.terraos-new1.public_ip
  }
    inline =[
      "sudo yum install httpd -y",
    
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]

}
  tags = {
        Name = "terraos1"
  }
}
resource "null_resource" "nullr"{
 
  depends_on = [ aws_instance.terraos-new1,aws_efs_mount_target.alpha,]
   
   provisioner "remote-exec" {
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("C:/Users/muska/Downloads/terrakey-new.pem")}"
    host     = aws_instance.terraos-new1.public_ip
  }
   inline=[
     //"sudo su - root",
     "sudo yum install -y nfs-utils",
     "sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.alpha.dns_name}:/ /var/www/html",
     "sudo cd /var/www/html",
     // "sudo su - root",
           "sudo yum install -y git",
      "sudo git clone https://github.com/muskan399/first.git /var/www/html",
     //"echo  My Instance! >> /var/www/html/index.html",
     "sudo setenforce 0",
     "sudo systemctl start httpd"
]


}
}
output "out1" {
value=aws_instance.terraos-new1.public_ip
}
resource "aws_efs_file_system" "foo" {
  creation_token = "my-product"
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id = "${aws_efs_file_system.foo.id}"
  subnet_id      = "${aws_instance.terraos-new1.subnet_id}"
  security_groups = ["${aws_security_group.terrasg2.id}"]
}


