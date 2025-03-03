variable "aws_instance_type" {
    description = "The type of EC2 instance to launch"
    type = "string"
    default = "t2.micro"   // change it if you want to use another instance type
}

variable "ami_id" {
    description = "value of AMI Id"
    default = "ami-0c55b159cbfafe1f0"  // Amazon Linux 2 AMI, change it if you want to use another AMI
}

variable "cidr" {
    default = "10.0.0.0/16" // change it if you want to use another CIDR block
}


