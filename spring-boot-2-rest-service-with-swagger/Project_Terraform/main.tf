resource "my_vpc" "myvpc" {
    name = "my-vpc"
    cidr_vlock = var.cidr
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
    name = "my-sg"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "my-sg"
    }
}

terraform {
  backend "s3" {
    bucket         = "my-web-assets-bucket"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock" // DynamoDB table name
  }
}

resource "aws_s3_bucket" "bucket" {
    bucket = "my-bucket123"    // Bucket name should be unique, so change it
}

resource "aws_instance" "webserver1" {
    ami           = var.ami_id  // Amazon Linux 2 AMI, change it if you want to use another AMI
    instance_type = var.aws_instance_type
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id     = aws_subnet.sub1.id
    user_data     = base64decode(file("userdata.sh"))

}

resource "aws_instance" "webserver2" {
    ami           = var.ami_id
    instance_type = var.aws_instance_type
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id = aws_subnet.sub2.id
    user_data     = base64decode(file("userdata.sh"))
}

resource "aws_launch_template" "web_server" {
  name_prefix   = "web-server-"  // Name prefix for the launch template
  image_id      = var.ami_id  // Amazon Linux 2 AMI
  instance_type = var.aws_instance_type 
  user_data     =  base64encode(file("userdata.sh"))

    network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.sg.id]
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = [aws_subnet.sub1.id, aws_subnet.sub2.id] # Replace with actual subnet ID
  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }
}


resource "aws_lb" "myalb" {
    name               = "myalb"
    internal           = false
    load_balancer_type = "application"

    security_groups = [aws_security_group.sg.id]
    subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id] // Replace with your actual subnet IDs

    tags = {
        Name = "myalb"
    }
}

resource "aws_lb_target_group" "mytg" {
    name = "mytg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id // Replace with your actual VPC ID

    health_check {
        path = "/"
        port = "traffic-port"
    }
}

resource "aws_lb_target_group_attachment" "attach1" {
    target_group_arn = aws_lb_target_group.mytg.arn
    target_id        = aws_instance.webserver1.id
    port             = 80
}

resource "aws_tg_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.mytg.arn
    target_id        = aws_instance.webserver2.Id
    port             = 80
}

resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.myalb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.mytg.arn
    }
}

resource "aws_autoscaling_attachment" "web_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
