# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "my_jenkins_sg" {
  name        = "my-jenkins-sg"
  description = "Open ports 22, 443, and 8080"

  ingress {
    description = "incoming SSH"
    from_port   = 22
    to_port     = 22
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

  ingress {
    description = "incoming 8080"
    from_port   = 8080
    to_port     = 8080
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

# The EC2 instance defined here in the resource block will host a Jenkins server
resource "aws_instance" "My_jenkins_server" {
  ami                    = "ami-09988af04120b3591"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_jenkins_sg.id]
  subnet_id              = "subnet-09cadfd376d54d717"
  key_name               = "Week20"

  tags = {
    Name = "My_jenkins_server"
  }

  # Specify custom script that Terraform executes when launching EC2 instance
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade -y
    sudo amazon-linux-extras install java-openjdk11 -y
    sudo dnf install java-11-amazon-corretto -y
    sudo yum install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  EOF
}

# Create an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins" {
  bucket = "jenkins-${random_id.randomness.hex}"

  tags = {
    Name = "jenkins"
  }
}

# Deny public access
resource "aws_s3_bucket_public_access_block" "jenkins" {
  bucket = aws_s3_bucket.jenkins.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a random number for S3 bucket name
resource "random_id" "randomness" {
  byte_length = 12
}
