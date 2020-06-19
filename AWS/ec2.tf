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

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
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
      "sudo yum install git -y" ,
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]

}
  tags = {
        Name = "terraos1"
  }
}
resource "null_resource" "nullr"{
 
  depends_on = [aws_volume_attachment.terraebs1, aws_instance.terraos-new1,
  ]
   
   provisioner "remote-exec" {
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("C:/Users/muska/Downloads/terrakey-new.pem")}"
    host     = aws_instance.terraos-new1.public_ip
  }
   inline=[
   "sudo rm -rf /var/www/html",
   "sudo mkfs.ext4 /dev/xvdh",
   "sudo mount /dev/xvdh /var/www/html",
   "sudo git clone https://github.com/muskan399/first.git /var/www/html",
   "sudo setenforce 0",
   "sudo systemctl start httpd"
]


}
}
output "out1" {
value=aws_instance.terraos-new1.public_ip
}
//Creating EBS volume

resource "aws_ebs_volume" "terraebs-new1" {

  size              = 1
  tags = {
    Name = "terra_ebs"
  }
availability_zone="${aws_instance.terraos-new1.availability_zone}"
}

//Attaching EBS volume to myos instance

resource "aws_volume_attachment" "terraebs1" {
  
  depends_on = [aws_volume_attachment.terraebs1 ,
  ]
  device_name = "/dev/sdh"
  
  volume_id   = "${aws_ebs_volume.terraebs-new1.id}"
  instance_id = "${aws_instance.terraos-new1.id}"
  force_detach=true
  
}