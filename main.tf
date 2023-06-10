#Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
# Create a security group
resource "aws_security_group" "my_jenkins_sg" {
  name        = "my-jenkins-sg"
  description = "Open ports 22, 443, and 8080"
  vpc_id = aws_vpc.jenkins_vpc.id

  ingress {
    description = "incomming SSH"
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
    description = "incomming 8080"
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

# Create a VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "jenkins_vpc"
  }
}
resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "jenkins_vpc"
  }
}
#The EC2 instance defined here in the resource block will host a jenkins server
resource "aws_instance" "My_jenkins_server" {
  ami                    = "ami-09988af04120b3591" # Jenkins-compatible AMI ID
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.jenkins_subnet.id
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
}
#Create an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins" {
  bucket = "jenkins-${random_id.randomness.hex}"

  tags = {
    Name = "jenkins"
  }
}
#Deny public access
resource "aws_s3_bucket_ownership_controls" "jenkins" {
  bucket = aws_s3_bucket.jenkins.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
#Create random number for S3 bucket name
resource "random_id" "randomness" {
  byte_length = 12
}