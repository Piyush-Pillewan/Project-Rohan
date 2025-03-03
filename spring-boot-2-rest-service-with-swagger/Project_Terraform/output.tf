output "instance_ip" {
    description = "The public IP address of the EC2 instance"
    value = aws_instance.myec2.public_ip
}

output "instance_id" {
    description = "The instance ID of the EC2 instance"
    value = aws_instance.myec2.instance_id
}

output "loadbalancerdns" {
    value = aws_lb.myalb.dns_name
}
