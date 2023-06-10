#Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#The EC2 instance defined here in the resource block will host a jenkins server

resource "aws_instance" "My_jenkins_server" {
  ami           = "ami-09988af04120b3591" # Jenkins-compatible AMI ID
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_jenkins_sg.id]
  tags = {
    Name = "My_jenkins_server"
  }
  # Specify custom script that Terraform executes when launching EC2 instance
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo amazon-linux-extras install java-openjdk11 -y
  sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  sudo yum upgrade
  sudo yum install -y jenkins
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
EOF

  user_data_replace_on_change = true
}
resource "aws_security_group" "my_jenkins_sg" {
  name        = "my-jenkins-security-group"
  description = "access to ports 22, 443, and 8080"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Incoming 443"
    from_port   = 443
    to_port     = 443
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
    Name = "my_jenkins_sg"
  }
}

#Create an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins" {
  bucket = var.jenkins_s3_bucket_name
  }
}

Deny public access
resource "aws_s3_bucket_acl" "jenkins" {
  bucket = aws_s3_bucket.jenkins.id
  acl    = "private"
}