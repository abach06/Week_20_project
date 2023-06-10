#Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#The EC2 instance defined here in the resource block will host a jenkins server

resource "aws_instance" "My_jenkins_server" {
  ami           = "ami-09988af04120b3591  # Jenkins-compatible AMI ID
  instance_type = "t2.micro"
  tags = {
  security_group_ids = ["sg-0a544f46c36e61c9c"]  # ID of the security group allowing necessary inbound traffic
    Name = "My_jenkins_server"